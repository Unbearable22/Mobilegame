"""Structural diversity check: no typed topological clones under D4 transforms."""
import json
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]

def signature(data):
    variants = []
    for flip in (1, -1):
        for turns in range(4):
            points = []
            for node in data['nodes']:
                x, y = node['x'] * flip, node['y']
                for _ in range(turns): x, y = -y, x
                points.append((x,y,node['type'],node.get('rotatable',False),len(node.get('dirs',[]))))
            min_x = min(p[0] for p in points)
            min_y = min(p[1] for p in points)
            variants.append(tuple(sorted((x-min_x,y-min_y,*rest) for x,y,*rest in points)))
    return min(variants)

class DesignTests(unittest.TestCase):
    def test_hundred_distinct_authored_boards(self):
        seen = {}
        for id in range(1,101):
            data = json.loads((ROOT/f'levels/{id:02}.json').read_text())
            self.assertTrue(data['objective'].strip())
            self.assertTrue(data['author_solution'])
            key = signature(data)
            self.assertNotIn(key,seen,f"Level{id} duplicates level{seen.get(key)}")
            seen[key] = id
    def test_final_chapter_combines_all_seven_types(self):
        for id in range(41,51):
            data = json.loads((ROOT/f'levels/{id:02}.json').read_text())
            self.assertEqual(len({node['type'] for node in data['nodes']}),7)
    def test_three_order_tasks_declared(self):
        for id in (26,28,30):
            data = json.loads((ROOT/f'levels/{id:02}.json').read_text())
            self.assertEqual(len(data['required_source_order']),2)

if __name__=='__main__': unittest.main()
