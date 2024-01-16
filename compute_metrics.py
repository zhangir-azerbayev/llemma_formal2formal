import json
import glob
import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument('--input_dirs', nargs='+')

args = parser.parse_args()

for setting in args.input_dirs:
    fs = [json.load(open(x)) for x in glob.glob(os.path.join(setting, '*.json'))]
    n = 0
    ns = 0
    for f in fs:
        for result in f['results']:
            name = result['example']['full_name']

            # Extra helper theorem in the OpenAI code
            if 'sum_pairs' in name:
                continue

            n += 1
            if result['success']:
                ns += 1

    print(setting, ns/n, ns, n, sep='\t')

