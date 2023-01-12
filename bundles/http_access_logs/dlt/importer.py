import os
import sys

# Add parent directory to the import path.
# By default, DLT code adds only the directory of the notebooks
# it imports to the import path.
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))
