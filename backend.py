import numpy as np
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
from sklearn.metrics import pairwise_distances_argmin
# from sklearn.datasets import load_sample_image
import cv2
from sklearn.utils import shuffle
from time import time, sleep
from collections import Counter
import sys

N_COLORS = 16
SAT_LEVEL = 200
COLOR_DISTANCE = 10000

def recreate_image(codebook, labels, w, h):
    """Recreate the (compressed) image from the code book & labels"""
    d = codebook.shape[1]
    image = np.zeros((w, h, d))
    label_idx = 0
    for i in range(w):
        for j in range(h):
            image[i][j] = codebook[labels[label_idx]]
            label_idx += 1
    # print(image)
    return image

cap = cv2.VideoCapture(1)
while(1):
    # get a frame
    ret, frame = cap.read()
    frame_hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    (H, S, V) = cv2.split(frame_hsv)

    S = S.reshape(-1, 1)
    S = np.uint32(S)
    if np.mean(S) < SAT_LEVEL:
        S = S * SAT_LEVEL / np.mean(S)
    mask = (S > 255)
    S[mask] = 255
    S = S.reshape(H.shape)
    S = np.uint8(S)

    V = V.reshape(-1, 1)
    V = np.uint32(V)
    if np.mean(V) < 200:
        V = V * SAT_LEVEL / np.mean(V)
    mask = (V > 255)
    V[mask] = 255
    V = V.reshape(H.shape)
    V = np.uint8(V)

    frame_hsv = cv2.merge([H, S, V])
    frame = cv2.cvtColor(frame_hsv, cv2.COLOR_HSV2BGR)
    # show a frame
    cv2.imshow("capture", frame)

    # frame = cv2.imread("test3.jpg")
    frame = np.array(frame, dtype=np.float64) / 255

    w, h, d = original_shape = tuple(frame.shape)
    assert d == 3
    image_array = np.reshape(frame, (w * h, d))

    print("Fitting model on a small sub-sample of the data")
    t0 = time()
    image_array_sample = shuffle(image_array, random_state=0)[:1000]
    kmeans = KMeans(n_clusters=N_COLORS, tol=0.0001,
                    random_state=0).fit(image_array_sample)
    print("done in %0.3fs." % (time() - t0))

    # Get labels for all points
    print("Predicting color indices on the full image (k-means)")
    t0 = time()
    labels = kmeans.predict(image_array)
    print(labels, type(labels))
    print(kmeans.cluster_centers_, kmeans.cluster_centers_.shape)
    print("done in %0.3fs." % (time() - t0))

    test_color_count = np.zeros(N_COLORS)
    for i in range(N_COLORS):
        test_color_count[i] = list(labels).count(i)
    test_color_index = np.argsort(-test_color_count)

    darkest = (0, 255)
    for i in range(N_COLORS):
        gray = kmeans.cluster_centers_[test_color_index[i]] * 255
        gray = np.uint8(
            [[[int(gray[0]), int(gray[1]), int(gray[2])]]])
        gray = cv2.cvtColor(gray, cv2.COLOR_BGR2GRAY)
        gray = gray[0][0]
        if gray < 10 or gray > 240:
            continue
        if gray < darkest[1]:
            darkest = (i, gray)

    color_img = np.zeros((600, 300, 3), np.uint8)
    with open("butterfly.dat", "w") as f:
        first = test_color_index[darkest[0]]
        test_color_index = list(test_color_index)
        test_color_index.remove(darkest[0])
        index = [test_color_index[i] for i in range(N_COLORS - 1)]
        index.insert(0, first)

        record_colors = []
        abandoned_colors = []
        for i in index:
            color = kmeans.cluster_centers_[i] * 255
            color = np.uint8([[[int(color[0]), int(color[1]), int(color[2])]]])
            flag = 1
            for old_color in record_colors:
                if np.sum(np.square(np.uint32(color[0][0]) - np.uint32(old_color[0][0]))) < COLOR_DISTANCE:
                    flag = 0
                    break
            if flag == 1:
                record_colors.append(color)
            else:
                abandoned_colors.append(color)
                continue

            f.write("%d %d %d\n" %
                    (color[0][0][2], color[0][0][1], color[0][0][0]))
            print(color[0][0])
            for j in range(100):
                for k in range(300):
                    color_img[(len(record_colors) - 1) * 100 +
                              j][k] = np.uint8(color[0][0])
            if len(record_colors) >= 6:
                break

        if len(record_colors) < 6:
            print("others")
            for i in range(6 - len(record_colors)):
                color = abandoned_colors[i]
                f.write("%d %d %d\n" %
                        (color[0][0][2], color[0][0][1], color[0][0][0]))
                print(color[0][0])
                for j in range(100):
                    for k in range(300):
                        color_img[(len(record_colors) + i) * 100 +
                                  j][k] = np.uint8(color[0][0])

        serial = np.random.randint(1, 5)
        f.write("%d\n" % serial)

    cv2.imshow('Image', recreate_image(kmeans.cluster_centers_, labels, w, h))

    cv2.imshow('Colors', color_img)
    cv2.imwrite("colors.jpg", color_img)
    # cv2.waitKey(0)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

    # sleep(3)

cap.release()
cv2.destroyAllWindows()
