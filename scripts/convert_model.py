"""
scripts/convert_model.py
Convert your trained .h5 model → TFLite for Flutter

Usage:
    pip install tensorflow
    python scripts/convert_model.py --input model.h5 --output assets/models/bhaktapur_model.tflite --quant
"""

import argparse
import tensorflow as tf

def convert(input_path: str, output_path: str, quantize: bool = False):
    print(f"[1/3] Loading: {input_path}")
    model = tf.keras.models.load_model(input_path)

    print("[2/3] Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    if quantize:
        print("      ↳ INT8 dynamic range quantization enabled")
        converter.optimizations = [tf.lite.Optimize.DEFAULT]

    tflite_model = converter.convert()

    print(f"[3/3] Saving to: {output_path}")
    with open(output_path, "wb") as f:
        f.write(tflite_model)

    print(f"\n✅ Done! {len(tflite_model) / 1024:.1f} KB")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input",  required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--quant",  action="store_true")
    args = parser.parse_args()
    convert(args.input, args.output, args.quant)
