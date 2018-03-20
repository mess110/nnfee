import argparse
import tensorflow as tf

from fee_classifier import FeeClassifier
from shutil import rmtree

parser = argparse.ArgumentParser()
parser.add_argument('--predict', default='', type=str, help='predict something')
parser.add_argument('--train', default=False, help='do training', action='store_true')
parser.add_argument('--evaluate', default=False, help='do evaluation', action='store_true')
parser.add_argument('--clean', default=False, help='delete the existing model', action='store_true')
parser.add_argument('--batch_size', default=100, type=int, help='batch size')
parser.add_argument('--train_steps', default=1000, type=int, help='number of training steps')

def main(argv):
    args = parser.parse_args(argv[1:])

    if args.clean is True:
        rmtree(FeeClassifier.MODELS_DIR, ignore_errors=True)

    classifier = FeeClassifier(args.batch_size, args.train_steps)
    if args.train is True:
        classifier.train()
        args.evaluate = True

    if args.evaluate is True:
        classifier.evaluate()

    if args.predict is '':
        expected = [0, 1, 0, 1]
        predictorz = [
            [2.63, 9.66217041],
            [4.29, 18.03693676],
            [2.67,9.66217041],
            [1.18,18.03693676]
        ]
    else:
        input_list = eval(args.predict)
        if not isinstance(input_list, list):
            raise 'invalid --prediction, not an array'
        if len(input_list) != len(classifier.feature_column_names):
            raise 'invalid --prediction, invalid number of elements'
        predictorz = [input_list]
        expected = ['?']

    classifier.predict(predictorz, expected)

if __name__ == '__main__':
    # tf.logging.set_verbosity(tf.logging.INFO)
    tf.app.run(main)
