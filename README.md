# 📏 ObjectDiameterMeasurement  

A modern, interactive MATLAB-based tool for real-world object diameter and distance estimation using camera input or pre-captured images.  

---
<img width="1062" height="425" alt="Object4" src="https://github.com/user-attachments/assets/3acd53fe-6340-4a1f-a74e-4d127a69edde" />
<img width="1103" height="556" alt="Object1" src="https://github.com/user-attachments/assets/7038caed-133d-4f6c-b4e4-fa284687b22d" />

## 🚀 Overview  
**ObjectDiameterMeasurement** is a robust MATLAB application that enables users to estimate the real-world diameter of physical objects from images — either captured live via a camera (using the included `grab.exe` utility) or loaded from local files.  

The tool supports two measurement modes:  
- **Estimate Diameter** (when distance to the object is known)  
- **Estimate Distance** (when the object's real diameter is known)  

Using HSV color thresholding, the system isolates target objects, computes their pixel dimensions, and applies a simplified pinhole camera model to derive real-world metrics — all through an intuitive graphical interface.  

Perfect for educational labs, prototyping, or quick field measurements where precision tools aren’t available!  

---

## 🛠️ Features  
- ✅ **Dual Input Sources**: Load images from file or capture live via webcam (`grab.exe`)  
- 🎨 **Interactive HSV Thresholding**: Real-time sliders to fine-tune object detection  
- 📐 **Two Measurement Modes**:  
  - Known Distance → Estimate Diameter  
  - Known Diameter → Estimate Distance  
- 📊 **Visual Feedback**: Original image, HSV channels, mask, bounding boxes, and annotated results  
- 📤 **Export Results**: Automatically saves all measurements to `measurement_results.csv`  
- 🖼️ **Multi-Object Support**: Detects and measures multiple objects per image  
- 🔍 **User Validation**: Confirm object count before processing  

---

## 📦 Included Components  
- `object_diameter_measurement_gui.m` – Main MATLAB GUI application  
- `grab.exe` – Lightweight Windows utility to capture a single image from the default webcam and save it as `captured_image.jpg`  

💡 **Note**: `grab.exe` must be in the same directory as the MATLAB script or in your system PATH.  

---

## 🧪 Requirements  
- MATLAB R2020a or later (with Image Processing Toolbox)  
- Windows OS (for `grab.exe` compatibility)  
- Webcam (if using "From Camera" mode)  

🌐 **Linux/macOS users**: Replace `grab.exe` with a compatible image capture script (e.g., using `fswebcam` or OpenCV).  

---

## ▶️ Quick Start  
1. Clone or download this project to your local machine.  
2. Ensure `grab.exe` and `object_diameter_measurement_gui.m` are in the same folder.  
3. Open MATLAB and navigate to the project directory.  
4. Run the application:  

```matlab
object_diameter_measurement_gui
```
# 📸 How It Works

## 🖼️ Image Acquisition
- **If using camera**: `grab.exe` captures and saves `captured_image.jpg`  
- **If from file**: user selects one or more images  

## 🎨 Color Segmentation
- Converts image to **HSV color space**  
- Applies **user-defined thresholds** to isolate objects  
- Cleans mask (**hole filling, area filtering**)  

## 🔎 Object Detection
- Uses `regionprops` to extract **bounding boxes** and **axis lengths**  
- Sorts objects by **size (largest first)**  

## 📏 Real-World Estimation
Uses a simplified model:  

Real_Size = (Pixel_Size × Known_Distance) / Max_Image_Dimension

yaml
Copy code

- Assumes object is **centered** and **perpendicular to camera** (idealized setup)  

## 📤 Output
- Displays annotated images with measurements  
- Saves results to **measurement_results.csv**  

---

## 📁 Output Example (`measurement_results.csv`)

| IMAGE              | OBJECT ID | PIXEL DIAMETER | DIAMETER (MM) | DIAMETER (CM) | DISTANCE (MM) | DISTANCE (CM) | MODE                               |
|--------------------|-----------|----------------|---------------|---------------|---------------|---------------|------------------------------------|
| captured_image.jpg | Object 1  | 210.5          | 42.10         | 4.21          | 300           | 30.0          | Estimate Diameter (Know Distance)  |
| ball.png           | Object 1  | 180.0          | 60.00         | 6.00          | 450.0         | 45.0          | Estimate Distance (Know Diameter)  |

---

## ⚠️ Limitations & Notes
- Accuracy depends on setup. For best results:  
  - Object is **flat and perpendicular** to camera  
  - Known distance measured from **camera sensor** (lens position)  
  - Ensure **uniform lighting** and **minimal background clutter**  
- `grab.exe` is **Windows-only** – unsigned (may trigger antivirus warnings).  
  → Use open-source alternatives for production.  
- Simplified geometric model → **not a substitute** for calibrated machine vision.  

---

## 🔒 License
**MIT License** – see `LICENSE` for details.  

> Use responsibly. Not intended for **medical**, **safety-critical**, or **high-precision industrial** applications.  

---

## 🙌 Contributing
Found a bug? Have an idea for improvement?  
→ **Open an Issue** or **submit a Pull Request**!  

---

## 📬 Contact
- 📧 Email: **nazmulhaque.green@gmail.com**  
- 🌐 Website/GitHub:**https://github.com/nazmul-haque-nihal** 

---

> “Measure twice, cut once” — now with computer vision! 🔍📐
