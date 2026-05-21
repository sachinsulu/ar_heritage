"""
scripts/convert_model.py
Convert a trained Keras student model → TFLite for Flutter

Usage (matching the nyatapola_student_v4 pipeline):
    pip install tensorflow
    python scripts/convert_model.py \
        --input  nyatapola_student_v3_best.keras \
        --output assets/models/nyatapola_student_v4.tflite

    # With INT8 dynamic-range quantisation (reduces size ~4x, minimal accuracy loss):
    python scripts/convert_model.py \
        --input  nyatapola_student_v3_best.keras \
        --output assets/models/nyatapola_student_v4.tflite \
        --quant

Model contract (must match lib/core/constants/app_constants.dart):
    Input  shape : [1, 160, 160, 3]  float32  normalised to [0, 1] (divide by 255)
    Output shape : [1, 1]            float32  sigmoid
      ~0.0 → nyatapola_temple   (confidence = 1 - raw)
      ~1.0 → others             (confidence = raw)
"""

import argparse
import tensorflow as tf


def convert(input_path: str, output_path: str, quantize: bool = False):
    print(f"[1/4] Loading model: {input_path}")
    model = tf.keras.models.load_model(input_path)

    print(f"      Input  shape : {model.input_shape}")
    print(f"      Output shape : {model.output_shape}")

    assert model.input_shape == (None, 160, 160, 3), (
        f"Expected input (None,160,160,3), got {model.input_shape}"
    )
    assert model.output_shape == (None, 1), (
        f"Expected output (None,1), got {model.output_shape}"
    )

    print("[2/4] Creating TFLite converter...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    if quantize:
        print("      ↳ INT8 dynamic range quantisation enabled")
        converter.optimizations = [tf.lite.Optimize.DEFAULT]

    print("[3/4] Converting...")
    tflite_model = converter.convert()

    print(f"[4/4] Saving to: {output_path}")
    with open(output_path, "wb") as f:
        f.write(tflite_model)

    size_kb = len(tflite_model) / 1024
    print(f"\n✅ Done!  {size_kb:.1f} KB  ({size_kb/1024:.2f} MB)")
    print(f"   Drop the .tflite file at: assets/models/nyatapola_student_v4.tflite")
    print(f"   Update AppConstants.modelPath if the filename changes.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert Keras → TFLite")
    parser.add_argument("--input",  required=True,  help="Path to .keras or .h5 model")
    parser.add_argument("--output", required=True,  help="Output .tflite path")
    parser.add_argument("--quant",  action="store_true",
                        help="Apply INT8 dynamic-range quantisation")
    args = parser.parse_args()
    convert(args.input, args.output, args.quant)
