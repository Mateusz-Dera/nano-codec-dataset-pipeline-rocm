from datasets import load_dataset, Audio, disable_progress_bars
from typing import Dict, Any
from utils.config_manager import DatasetConfig
import os

# Disable HuggingFace progress bars globally
disable_progress_bars()


class DatasetProcessor:
    """Handles loading and preprocessing of datasets (HuggingFace or local)"""

    def __init__(self, dataset_config: DatasetConfig, sample_rate: int = 22050):
        self.config = dataset_config
        self.sample_rate = sample_rate
        self.dataset = None

    def _is_local_path(self, path: str) -> bool:
        """Check if the path is a local directory"""
        return os.path.isdir(path)

    def load_dataset(self, num_proc: int = 5) -> None:
        """Load dataset from HuggingFace or local directory (auto-detected)"""
        dataset_desc = f"{self.config.name}"
        if self.config.sub_name:
            dataset_desc += f" ({self.config.sub_name})"
        dataset_desc += f" [{self.config.split}]"

        # Auto-detect if this is a local path
        is_local = self._is_local_path(self.config.name)

        if is_local:
            print(f"📦 Loading local dataset: {dataset_desc}")
            print(f"   Path: {self.config.name}")

            # Load from local directory
            self.dataset = load_dataset(
                self.config.name,
                split=self.config.split,
                verification_mode='no_checks',
                trust_remote_code=True
            ).cast_column(self.config.audio_column_name, Audio(self.sample_rate))
        else:
            print(f"📦 Loading HuggingFace dataset: {dataset_desc}")

            # Load from HuggingFace
            self.dataset = load_dataset(
                self.config.name,
                self.config.sub_name,  # Can be None
                num_proc=num_proc,
                split=self.config.split,
                verification_mode='no_checks',  # Skip verification to reduce logs
                trust_remote_code=True  # Allow datasets with custom code
            ).cast_column(self.config.audio_column_name, Audio(self.sample_rate))

        print(f"  ✅ Loaded {len(self.dataset)} samples from {dataset_desc}")

    def get_dataset(self):
        """Get the loaded dataset"""
        if self.dataset is None:
            raise ValueError("Dataset not loaded. Call load_dataset() first.")
        return self.dataset

    def prepare_item(self, item: Dict[str, Any]) -> Dict[str, Any]:
        """
        Prepare a single item for processing.
        Extracts text, audio, speaker (if specified), and adds constant fields.
        """
        prepared = {
            "text": item[self.config.text_column_name],
            "wave": item[self.config.audio_column_name]["array"],
        }

        # Add speaker column if specified in config
        if self.config.speaker_column_name:
            prepared["speaker"] = item[self.config.speaker_column_name]

        # Add constant fields from config
        constant_cols = self.config.get_constant_columns()
        prepared.update(constant_cols)

        return prepared
