from . import *

class TestStack(TestCase):
    
    def test_push_and_pop(self):
        cpu = self.assemble_and_run('''
            set PUSH, 1
            set PUSH, 2
            set A, POP
            set PUSH, 3
        ''')
        self.assertEqual(cpu[0xffff], 1)
        self.assertEqual(cpu[0xfffe], 3)
        self.assertEqual(cpu['A'], 2)

    def test_getting_peek(self):
        cpu = self.assemble_and_run('''
            set PUSH, 1
            set A, PEEK
            set PUSH, 2
            set B, PEEK
        ''')
        self.assertEqual(cpu[0xffff], 1)
        self.assertEqual(cpu[0xfffe], 2)
        self.assertEqual(cpu['A'], 1)
        self.assertEqual(cpu['B'], 2)
        
    def test_setting_peek(self):
        cpu = self.assemble_and_run('''
            set PUSH, 1
            set PEEK, 2
            set PUSH, 3
            set PEEK, 4
        ''')
        self.assertEqual(cpu[0xffff], 2)
        self.assertEqual(cpu[0xfffe], 4)
    
    def test_getting_peek(self):
        cpu = self.assemble_and_run('''
            set PUSH, 1
            set PUSH, 2
            set PUSH, 3
            set A, PICK 1
            set B, PICK 2
        ''')
        self.assertEqual(cpu[0xffff], 1)
        self.assertEqual(cpu[0xfffe], 2)
        self.assertEqual(cpu[0xfffd], 3)
        self.assertEqual(cpu['A'], 2)
        self.assertEqual(cpu['B'], 1)
    
    def test_setting_pick(self):
        cpu = self.assemble_and_run('''
            set PUSH, 1
            set PUSH, 2
            set PICK 1, 3
        ''')
        self.assertEqual(cpu[0xffff], 3)
        self.assertEqual(cpu[0xfffe], 2)
        
        

