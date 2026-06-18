"""Shared setup for example scripts: path, headless matplotlib, figure dir."""
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import matplotlib
matplotlib.use("Agg")  # headless / CI-safe
import matplotlib.pyplot as plt  # noqa: E402

FIG_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "figures"))
os.makedirs(FIG_DIR, exist_ok=True)

# A consistent NASA-ish dark engineering style for all figures.
plt.rcParams.update({
    "figure.facecolor": "#0b1020",
    "axes.facecolor": "#0b1020",
    "axes.edgecolor": "#5a6a9a",
    "axes.labelcolor": "#dce3ff",
    "text.color": "#dce3ff",
    "xtick.color": "#aab4dd",
    "ytick.color": "#aab4dd",
    "grid.color": "#26304f",
    "axes.grid": True,
    "figure.dpi": 120,
    "savefig.dpi": 130,
    "font.size": 10,
})

ACCENT = "#4fc3f7"
ACCENT2 = "#ff7043"
ACCENT3 = "#9ccc65"
ACCENT4 = "#ffca28"


def save(fig, name):
    path = os.path.join(FIG_DIR, name)
    fig.savefig(path, bbox_inches="tight", facecolor=fig.get_facecolor())
    print(f"  wrote {os.path.relpath(path)}")
    return path
