# 🧠 BCI-LDA-FFT: Motor Imagery Classification Using FFT-Based Power Spectrum Features

## 📘 Overview
This project implements a **subject-specific EEG classification pipeline** for the **BCI Competition IV-2a (Graz dataset)**.  
It extracts **Foot vs Idle (eyes-open/eyes-closed)** trials from `.gdf` files, computes **FFT-based power-spectrum features**, and classifies them using **Linear Discriminant Analysis (LDA)**.  

The code is organized into modular MATLAB functions with clear separation between:
- **Signal loading and preprocessing**
- **Feature extraction (FFT-based PSD)**
- **Classification and evaluation**
- **Result logging and CSV export**

Two sets of metrics are reported per subject:
1. **Training metrics** – performance of LDA on the entire training session.  
2. **Cross-validation metrics** – 5-fold stratified evaluation for robustness estimation.  

---

## 🗂️ Project Structure

```
BCI-LDA-FFT/
│
├── main.m                         # Main execution script (runs full pipeline)
│
├── load_bci_gdf.m                 # Loads EEG & event info using BioSig’s sload()
├── extract_foot_and_rest.m        # Extracts Foot (771) and Rest (276,277) trials
├── features_from_epochs.m         # Loops through epochs → computes bandpower features
├── epoch_bandpowers.m             # Calls calc_PSD() → integrates PSD across μ/β bands
├── calc_PSD.m                     # FFT-based power spectrum (|FFT|² formulation)
├── calc_metrics.m                 # Computes Accuracy, Sensitivity, Specificity, Precision, F1
│
├── output/
│   └── csv_outputs/
│       ├── lda_train_only.csv     # Subject-wise metrics (fit on full training data)
│       ├── lda_cv_only.csv        # Subject-wise metrics (5-fold stratified CV)
│
└── README.md                      # Project documentation (this file)
```

---

## ⚙️ Dependencies
- **MATLAB R2022a+**
- **BioSig toolbox** for reading `.gdf` EEG files (`sload` function).  
  → Install via MATLAB Add-Ons or from [http://biosig.sourceforge.net](http://biosig.sourceforge.net).

---

## 🔄 Pipeline Summary

Each subject (`A01`–`A09`) is processed independently — reflecting the **subject-dependent** training paradigm of BCI Competition IV-2a.

### Step-by-Step Flow

#### 1. Dataset Loading
For each subject:
- Read the `.gdf` file (`A##T.gdf`) from `BCICIV_2a_gdf/`.
- Extract EEG signals (22 channels) and event markers.
- Identify Foot (771), Eyes-Open (276), and Eyes-Closed (277) events.

> Example:  
> ```
> [signal, header] = sload('BCICIV_2a_gdf/A01T.gdf');
> ```

#### 2. Epoch Extraction
From each event onset, take a **4-second window** (`2–6 s` post-cue).  
Each trial is labeled as **Foot = 1**, **Idle = 0**.

#### 3. FFT-Based PSD Calculation
Every epoch channel is transformed via FFT:

> *Power spectrum = (1 / 2πN) × |FFT(x)|²*

The frequencies are converted to Hz and integrated (via `trapz`) within the **μ-band (8–12 Hz)** and **β-band (13–30 Hz)**, yielding two features per channel.  
→ 22 channels × 2 bands = 44 features per trial.

#### 4. Feature Aggregation
All trial features are concatenated into matrices:
- **X ∈ [R×F]** → feature vectors  
- **y ∈ [R×1]** → class labels (Foot = 1, Idle = 0)

#### 5. Model Training (LDA)
A **Linear Discriminant Analysis** classifier is trained per subject using `fitcdiscr()`.

#### 6. Evaluation Metrics
- **Training metrics:** computed directly on the full dataset (fit performance).  
- **5-Fold Stratified Cross-Validation:** splits data into 5 folds, trains on 4, tests on 1, concatenates all predictions → final confusion matrix.

For both cases, the following metrics are derived:
| Metric | Definition |
|---------|-------------|
| Accuracy | (TP + TN)/(TP + TN + FP + FN) |
| Sensitivity (Recall) | TP/(TP + FN) |
| Specificity | TN/(TN + FP) |
| Precision | TP/(TP + FP) |
| F1-Score | 2 × (Precision × Recall)/(Precision + Recall) |

---

## 🧮 Main Script Breakdown

`main.m` controls the end-to-end execution. Its loop performs:

| Step | Operation | Description |
|------|------------|-------------|
| 1 | **Load subject file** | Reads `A##T.gdf` using BioSig. |
| 2 | **Extract epochs & labels** | Foot → 771, Idle → 276/277. |
| 3 | **Compute features** | Calls `features_from_epochs()` → `epoch_bandpowers()` → `calc_PSD()`. |
| 4 | **Train LDA model** | Fits `fitcdiscr()` on all samples. |
| 5 | **Compute TRAIN metrics** | Predict on full data → `calc_metrics()`. |
| 6 | **5-Fold CV evaluation** | Stratified partition, aggregate all out-of-fold predictions. |
| 7 | **Log & append results** | Print per-subject results; append to `results_train` and `results_cv`. |
| 8 | **Export CSVs** | Writes both tables into `output/csv_outputs/`. |

---

## 📊 Outputs

After execution, two CSV files are produced in:
```
output/csv_outputs/
│
├── lda_train_only.csv   ← Metrics from full training fit
└── lda_cv_only.csv      ← Metrics from 5-fold CV
```

Each file includes:
| Subject | Accuracy | Sensitivity | Specificity | F1_Score | Precision | (CV also: Acc_SD) |

Example (simplified):
```
Subject,Accuracy,Sensitivity,Specificity,F1_score,Precision
A01,0.92,0.88,0.94,0.90,0.89
A02,0.85,0.81,0.87,0.83,0.82
...
---

## 🧩 Future Extensions
- [x] Add frequency-band optimization (automated μ/β tuning).  
- [x] Add CSP (Common Spatial Patterns) features for comparison.  
- [x] Add transfer-learning or subject-independent modeling option.  
- [x] Integrate visualization for power spectra or LDA boundaries.
