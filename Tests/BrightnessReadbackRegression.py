#!/usr/bin/env python3
"""Compatibility entry for the production brightness contract fixture.
The new harness runs actual request, completion, step and DDC probe functions.
Protocol/state contracts also run in BrightnessPipelineTests.swift.
"""
from pathlib import Path
import subprocess
import sys
source = sys.argv[1] if len(sys.argv) > 1 else "Sources/Vorssaint/Services/Display/BrightnessService.swift"
suffix = sys.argv[2] if len(sys.argv) > 2 else "regression"
output = Path(".build/brightness-readback") / suffix / "main.swift"
subprocess.run([sys.executable, "Tests/BrightnessServiceContract.py", source, str(output)], check=True)
