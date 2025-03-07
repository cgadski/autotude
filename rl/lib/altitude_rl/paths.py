from pathlib import Path
import os

PROJECT_ROOT = Path(__file__).parent.parent.parent.parent
ALTI_HOME = Path(os.getenv("ALTI_HOME", PROJECT_ROOT / "alti_home"))
BIN = PROJECT_ROOT / "bin"
