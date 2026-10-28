import unittest

from app.app import greet


class GreetTest(unittest.TestCase):
    def test_default(self):
        self.assertEqual(greet(), {"message": "Hello, world!"})

    def test_name(self):
        self.assertEqual(greet("Jenkins"), {"message": "Hello, Jenkins!"})


if __name__ == "__main__":
    unittest.main()
