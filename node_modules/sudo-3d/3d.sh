#!/bin/bash

# Welcome Message
echo "Welcome to the 3D Model Viewer Setup Script!"

# Define file paths
HTML_FILE="index.html"
JS_FILE="main.js"
MODEL_FILE="public/model.glb"
MODEL_URL_DEFAULT="https://pub-c1de1cb456e74d6bbbee111ba9e6c757.r2.dev/model1.glb"
FAVICON_URL="https://pub-c1de1cb456e74d6bbbee111ba9e6c757.r2.dev/favicon.ico"
APPLE_TOUCH_ICON_URL="https://pub-c1de1cb456e74d6bbbee111ba9e6c757.r2.dev/apple-touch-icon.png"
VITE_CONFIG_FILE="vite.config.js"

# Prompt for the URL of the .glb file with a default value
read -p "Enter the URL of your .glb file (default: $MODEL_URL_DEFAULT): " glb_url
glb_url=${glb_url:-$MODEL_URL_DEFAULT}

# Create the project directory
PROJECT_DIR="sudo-3d"
echo "Creating project directory '$PROJECT_DIR'..."
mkdir -p $PROJECT_DIR && cd $PROJECT_DIR || { echo "Failed to create project directory. Exiting."; exit 1; }

# Initialize a new npm project
echo "Initializing npm project..."
npm init -y > /dev/null

# Install required dependencies
echo "Installing dependencies..."
npm install three > /dev/null
npm install vite @rollup/plugin-commonjs @rollup/plugin-node-resolve --save-dev > /dev/null

# Create necessary directories
echo "Creating public directory for assets..."
mkdir -p public

# Download files
download_file() {
  local url=$1
  local output=$2
  echo "Downloading $output from $url..."
  if curl -f -o "$output" "$url"; then
    echo "Downloaded $output successfully."
  else
    echo "Failed to download $output from $url. Skipping."
  fi
}

download_file "$glb_url" "$MODEL_FILE"
download_file "$FAVICON_URL" "public/favicon.ico"
download_file "$APPLE_TOUCH_ICON_URL" "public/apple-touch-icon.png"

# Create the main.js file
echo "Creating main.js..."
cat <<EOF >$JS_FILE
import * as THREE from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";

// Set up the scene and camera
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x000000);
const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);

// Set up the renderer
const renderer = new THREE.WebGLRenderer();
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setAnimationLoop(animate);
document.body.appendChild(renderer.domElement);

// Add lights
const ambientLight = new THREE.AmbientLight(0x404040, 2);
scene.add(ambientLight);

const directionalLight = new THREE.DirectionalLight(0xffffff, 2);
directionalLight.position.set(5, 5, 5).normalize();
scene.add(directionalLight);

const pointLight = new THREE.PointLight(0xffffff, 2, 100);
pointLight.position.set(0, 5, 5);
scene.add(pointLight);

// Load a GLB model
const loader = new GLTFLoader();
loader.load('/model.glb', (gltf) => {
    const model = gltf.scene;
    scene.add(model);

    // Adjust model scale and position
    model.scale.set(1, 1, 1);
    model.position.set(0, 5, 0);

    // Center the model
    const box = new THREE.Box3().setFromObject(model);
    const center = box.getCenter(new THREE.Vector3());
    model.position.sub(center);
}, undefined, (error) => {
    console.error(error);
});


// Position the camera
camera.position.set(0, 1, 5);

// Add OrbitControls
const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(0, 0.5, 0); 
controls.update();

// Handle window resizing
window.addEventListener('resize', () => {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
});

function animate() {
    controls.update();
    renderer.render(scene, camera);
}
EOF

# Create the index.html file
echo "Creating index.html..."
cat <<EOF >$HTML_FILE
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <title>3D Model Viewer</title>
        <link rel="shortcut icon" href="public/favicon.ico">
        <link rel="icon" type="image/x-icon" sizes="16x16 32x32" href="public/favicon.ico">
        <link rel="apple-touch-icon" href="public/apple-touch-icon.png">
        <style>
            html, body {
                margin: 0;
                padding: 0;
                width: 100%;
                height: 100%;
                overflow: hidden;
            }
            canvas {
                display: block;
            }
        </style>
    </head>
    <body>
        <script type="module" src="main.js"></script>
    </body>
</html>
EOF

# Create the vite.config.js file
echo "Creating vite.config.js..."
cat <<EOF >$VITE_CONFIG_FILE
import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    rollupOptions: {
      input: './index.html',
    },
  },
  server: {
    open: true,
  },
});
EOF

# Completion message
echo "3d Website build complete! Starting the development server..."

# Run the Vite development server
sudo npx vite

