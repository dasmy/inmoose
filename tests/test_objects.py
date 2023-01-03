import unittest
import numpy as np
import edgepy

class test_objects(unittest.TestCase):
    def test_is_integer(self):
        arr = np.array([0,1,2], dtype='int')
        self.assertEqual(edgepy.is_integer_array(arr), True)

        arr = np.array([0,1,2], dtype='double')
        self.assertEqual(edgepy.is_integer_array(arr), False)

        arr = np.array([0,1,2], dtype='str')
        with self.assertRaisesRegex(RuntimeError, expected_regex="array dtype is neither 'int' nor 'double'"):
            edgepy.is_integer_array(arr)

if __name__ == '__main__':
    unittest.main()
