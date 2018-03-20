from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import estimate_data
import tensorflow as tf

class FeeClassifier:

    def __init__(self, batch_size, train_steps):
        self.batch_size = batch_size
        self.train_steps = train_steps
        self.feature_column_names = []

        my_feature_columns = []
        for key in estimate_data.load_train_keys():
            feature_column = tf.feature_column.numeric_column(key=key)
            my_feature_columns.append(feature_column)
            self.feature_column_names.append(feature_column.name)

        # Build 2 hidden layer DNN with 10, 10 units respectively.
        self.classifier = tf.estimator.DNNClassifier(
            feature_columns=my_feature_columns,
            # Two hidden layers of 10 nodes each.
            hidden_units=[10, 10],
            # The model must choose between 3 classes.
            n_classes=8,
            model_dir='models/')


    def train(self):
        train_x, train_y = estimate_data.load_training_data()

        # Train the Model.
        self.classifier.train(
            input_fn=lambda:estimate_data.train_input_fn(train_x, train_y, self.batch_size),
            steps=self.train_steps)


    def evaluate(self):
        test_x, test_y = estimate_data.load_test_data()

        # Evaluate the model.
        eval_result = self.classifier.evaluate(
            input_fn=lambda:estimate_data.eval_input_fn(test_x, test_y,
                                                    self.batch_size))

        print('Test set accuracy: {accuracy:0.3f}\n'.format(**eval_result))


    def predict(self, predict, expected):
        predict_x = {}

        # format to expected predict format
        index = -1
        for key in self.feature_column_names:
            index += 1
            new_array = []
            for elem in predict:
                new_array.append(elem[index])
            predict_x[key] = new_array
        # print(predict_x)

        predictions = self.classifier.predict(
            input_fn=lambda:estimate_data.eval_input_fn(predict_x,
                                                    labels=None,
                                                    batch_size=self.batch_size))

        template = ('Prediction is "{}" ({:.1f}%), expected "{}"\n')

        for pred_dict, expec in zip(predictions, expected):
            class_id = pred_dict['class_ids'][0]
            probability = pred_dict['probabilities'][class_id]

            print(template.format(class_id, 100 * probability, expec))
