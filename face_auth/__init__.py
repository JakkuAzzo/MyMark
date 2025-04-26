import numpy as np
import cv2
from pathlib import Path
from mtcnn import MTCNN
import tensorflow as tf

MODEL_PATH = Path(__file__).parent / "20180408-102900.pb"

tf.compat.v1.disable_eager_execution()
graph = tf.Graph()
with graph.as_default():
    graph_def = tf.compat.v1.GraphDef()
    graph_def.ParseFromString(MODEL_PATH.read_bytes())
    tf.import_graph_def(graph_def, name="")
sess = tf.compat.v1.Session(graph=graph)

images_placeholder = graph.get_tensor_by_name("input:0")
embeddings = graph.get_tensor_by_name("embeddings:0")
phase_train = graph.get_tensor_by_name("phase_train:0")

detector = MTCNN()

def _prewhiten(img):
    mean, std = img.mean(), img.std()
    std_adj = np.maximum(std, 1.0/np.sqrt(img.size))
    return (img - mean) / std_adj

def face_embedding(bgr_img) -> np.ndarray | None:
    """Return 128-D embedding or None if no face found."""
    rgb = cv2.cvtColor(bgr_img, cv2.COLOR_BGR2RGB)
    faces = detector.detect_faces(rgb)
    if not faces:
        return None
    x, y, w, h = faces[0]["box"]
    face = rgb[y:y+h, x:x+w]
    face = cv2.resize(face, (160, 160))
    face = _prewhiten(face)
    feed_dict = {images_placeholder: [face], phase_train: False}
    return sess.run(embeddings, feed_dict=feed_dict)[0]  # shape (128,)
