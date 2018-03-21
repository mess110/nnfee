import os
import pandas as pd
import tensorflow as tf

CSV_TRAINING_PATH = os.getenv('CSV_TRAINING_PATH', 'data/csv/fee_training.csv')
CSV_TEST_PATH = os.getenv('CSV_TEST_PATH', 'data/csv/fee_test.csv')


def load_data(test=True):
    """Returns the iris dataset as train_x, train_y"""
    csv_path = CSV_TEST_PATH if test is True else CSV_TRAINING_PATH
    csv = pd.read_csv(csv_path)
    y_name = list(csv.columns.values).pop()
    csv_x, csv_y = csv, csv.pop(y_name)
    return csv_x, csv_y


def load_test_data():
    return load_data(True)


def load_training_data():
    return load_data(False)


def load_train_keys():
    """Reads the headers of the csv_file"""
    path = CSV_TEST_PATH
    csv = pd.read_csv(path, nrows=1)
    y_name = list(csv.columns.values).pop()
    csv.pop(y_name)
    return csv.keys()


def train_input_fn(features, labels, batch_size):
    """An input function for training"""
    # Convert the inputs to a Dataset.
    dataset = tf.data.Dataset.from_tensor_slices((dict(features), labels))

    # Shuffle, repeat, and batch the examples.
    dataset = dataset.shuffle(1000).repeat().batch(batch_size)

    # Return the dataset.
    return dataset


def eval_input_fn(features, labels, batch_size):
    """An input function for evaluation or prediction"""
    features = dict(features)
    if labels is None:
        # No labels, use only features.
        inputs = features
    else:
        inputs = (features, labels)

    # Convert the inputs to a Dataset.
    dataset = tf.data.Dataset.from_tensor_slices(inputs)

    # Batch the examples
    assert batch_size is not None, "batch_size must not be None"
    dataset = dataset.batch(batch_size)

    # Return the dataset.
    return dataset
