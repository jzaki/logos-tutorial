# Tutorial Part 2: Building a QML UI for Your Logos Module

This is Part 2 of the Logos module tutorial series. In [Part 1](tutorial-wrapping-c-library.md) you wrapped a C library as a Logos core module. Now you'll build a **QML user interface** that calls that module — first isolated with `nix run`, then packaged and loaded into `logos-basecamp`.

**What you'll build:** A `calc_ui` QML plugin with input fields and buttons that call `calc_module` methods (add, multiply, factorial, fibonacci) through the Logos bridge.

**What you'll learn:**

- How QML UI plugins work in the Logos platform
- The `logos.callModule()` bridge that connects QML to core modules
- The project structure and metadata for a QML plugin
- How to package and install your UI into `logos-basecamp`

**Prerequisites:**

- Completed [Part 1](tutorial-wrapping-c-library.md) — you have a working `calc_module`
- Nix with flakes enabled (same as Part 1)
- Basic familiarity with QML (Qt's declarative UI language)

---

## How QML UI Plugins Work

Before writing code, let's understand the architecture:

```
+-------------------+     logos.callModule()      +-------------------+
|    calc_ui        | --------------------------> |   calc_module     |
|  Main.qml (QML)   |     IPC (Qt Remote Objects) |   C++ plugin      |
+-------------------+                             +-------------------+
        ^                                                  ^
        └──────────────── loaded by ───────────────────────┘
                     logos-basecamp / logos-standalone-app
```

Key points:

- **No compilation.** A QML plugin is just `.qml` files and a `metadata.json`.
- **Sandboxed.** No network access, no filesystem access outside the module directory.
- **The `logos` bridge** is injected by the host. Call core modules with `logos.callModule("module", "method", [args])`.
- **Entry point** is always `Main.qml`.

---

## Step 1: Scaffold

Use the QML module template from `logos-module-builder`:

```bash
mkdir logos-calc-ui && cd logos-calc-ui
nix flake init -t github:logos-co/logos-module-builder#ui-qml-module
git init && git add -A
```

This gives you:

```
logos-calc-ui/
├── flake.nix       # Nix build + nix run support
├── metadata.json   # Plugin metadata
└── Main.qml        # Your UI (starter template)
```

---

## Step 2: Update `metadata.json`

Replace the template contents with your plugin's details:

```json
{
  "name": "calc_ui",
  "version": "1.0.0",
  "description": "Calculator UI - QML frontend for the calc_module",
  "type": "ui_qml",
  "main": "Main.qml",
  "dependencies": ["calc_module"],
  "category": "tools",
  "icon": "icons/calc.png"
}
```

The `dependencies` field tells the host to load `calc_module` before showing your UI.

---

## Step 3: Write `Main.qml`

Replace the starter file with the calculator UI:

```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string result: ""
    property string errorText: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // ── Title ──────────────────────────────────────────────
        Text {
            text: "Logos Calculator"
            font.pixelSize: 20
            font.weight: Font.DemiBold
            color: "#ffffff"
            Layout.alignment: Qt.AlignHCenter
        }

        // ── Two-operand operations ─────────────────────────────
        RowLayout {
            spacing: 12
            Layout.fillWidth: true

            TextField {
                id: inputA
                placeholderText: "a"
                Layout.preferredWidth: 80
                validator: IntValidator {}
            }

            TextField {
                id: inputB
                placeholderText: "b"
                Layout.preferredWidth: 80
                validator: IntValidator {}
            }

            Button {
                text: "Add"
                onClicked: callTwoOp("add", inputA.text, inputB.text)
            }

            Button {
                text: "Multiply"
                onClicked: callTwoOp("multiply", inputA.text, inputB.text)
            }
        }

        // ── Single-operand operations ──────────────────────────
        RowLayout {
            spacing: 12
            Layout.fillWidth: true

            TextField {
                id: inputN
                placeholderText: "n"
                Layout.preferredWidth: 80
                validator: IntValidator { bottom: 0 }
            }

            Button {
                text: "Factorial"
                onClicked: callOneOp("factorial", inputN.text)
            }

            Button {
                text: "Fibonacci"
                onClicked: callOneOp("fibonacci", inputN.text)
            }

            Button {
                text: "libcalc version"
                onClicked: callModule("libVersion", [])
            }
        }

        // ── Result display ─────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: root.errorText.length > 0 ? "#3d1a1a" : "#1a2d1a"
            radius: 8

            Text {
                anchors.centerIn: parent
                text: root.errorText.length > 0 ? root.errorText
                        : (root.result.length > 0 ? root.result : "Enter values and press a button")
                color: root.errorText.length > 0 ? "#f85149" : "#56d364"
                font.pixelSize: 15
            }
        }

        Item { Layout.fillHeight: true }
    }

    // ── Logos bridge helpers ───────────────────────────────────

    function callModule(method, args) {
        root.errorText = ""
        root.result = ""

        if (typeof logos === "undefined" || !logos.callModule) {
            root.errorText = "Logos bridge not available"
            return
        }

        root.result = String(logos.callModule("calc_module", method, args))
    }

    function callTwoOp(method, a, b) {
        if (a === "" || b === "") { root.errorText = "Enter values for a and b"; return }
        callModule(method, [parseInt(a), parseInt(b)])
    }

    function callOneOp(method, n) {
        if (n === "") { root.errorText = "Enter a value for n"; return }
        callModule(method, [parseInt(n)])
    }
}
```

The `logos` object is injected by the host at runtime. The `callModule` helper checks for it and routes calls through the IPC bridge to `calc_module`.

---

## Step 4: Update `flake.nix`

The template already has `logos-standalone-app` wired up. The only change needed is to update the description and pname:

```nix
{
  description = "Calculator QML UI Plugin for Logos - frontend for calc_module";

  inputs = {
    logos-nix.url = "github:logos-co/logos-nix";
    nixpkgs.follows = "logos-nix/nixpkgs";

    logos-standalone-app.url = "github:logos-co/logos-standalone-app";
    logos-standalone-app.inputs.logos-liblogos.inputs.nixpkgs.follows =
      "logos-nix/nixpkgs";
  };

  outputs = { self, nixpkgs, logos-standalone-app, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in {
      packages = forAllSystems ({ pkgs }: let
        plugin = pkgs.stdenv.mkDerivation {
          pname = "logos-calc-ui-plugin";
          version = "1.0.0";
          src = ./.;
          phases = [ "unpackPhase" "installPhase" ];
          installPhase = ''
            mkdir -p $out/lib/icons
            cp $src/Main.qml      $out/lib/Main.qml
            cp $src/metadata.json $out/lib/metadata.json
            if [ -f "$src/icons/calc.png" ]; then
              cp $src/icons/calc.png $out/lib/icons/calc.png
            fi
          '';
        };
      in { default = plugin; lib = plugin; });

      apps = forAllSystems ({ pkgs }:
        let
          standalone = logos-standalone-app.packages.${pkgs.system}.default;
          plugin = self.packages.${pkgs.system}.default;
          run = pkgs.writeShellScript "run-calc-ui-standalone" ''
            exec ${standalone}/bin/logos-standalone "${plugin}/lib" "$@"
          '';
        in { default = { type = "app"; program = "${run}"; }; }
      );
    };
}
```

The `installPhase` copies only `Main.qml` and `metadata.json` to `$out/lib/`. The `apps` output wires up `logos-standalone-app` so `nix run .` works.

---

## Step 5: Test with `nix run`

### 5.1 UI only (layout preview)

```bash
git add -A
nix run .
```

The app opens immediately. No modules are loaded, so clicking buttons shows "Logos bridge not available" — but you can verify the layout and styling look correct.

### 5.2 Full functionality (with modules)

To test actual calls to `calc_module`, you need a modules directory with `capability_module` (required by all UI plugins) and `calc_module` installed via `lgpm`. Do this once:

```bash
nix build 'github:logos-co/logos-package-manager-module#cli' --out-link ./pm
mkdir -p modules

# Install capability_module (required by all UI plugins)
nix bundle --bundler 'github:logos-co/nix-bundle-lgx' \
  'github:logos-co/logos-capability-module' -o lgx-capability
./pm/bin/lgpm --modules-dir ./modules install --file lgx-capability/*.lgx

# Bundle and install calc_module (from Part 1)
cd ../logos-calc-module
nix bundle --bundler 'github:logos-co/nix-bundle-lgx' '.#lib' -o lgx-result
cd ../logos-calc-ui
./pm/bin/lgpm --modules-dir ./modules install --file ../logos-calc-module/lgx-result/*.lgx
```

Then run with the modules directory:

```bash
nix run . -- --modules-dir ./modules
```

Clicking **Add**, **Multiply**, **Factorial**, or **Fibonacci** now calls the real module.

---

## Step 6: Using the Logos Design System

`logos-basecamp` has `logos-design-system` on its QML import path. You can use its themed components directly without any extra setup in your module.

```qml
import Logos.Theme 1.0
import Logos.Controls 1.0
```

Replace the plain `Button` and `TextField` with the styled equivalents:

```qml
// Instead of Button:
LogosButton {
    text: "Add"
    onClicked: callTwoOp("add", inputA.text, inputB.text)
}

// Instead of TextField:
LogosTextField {
    id: inputA
    placeholderText: "a"
}

// Use theme colors instead of hardcoded hex values:
Rectangle {
    color: Theme.palette.backgroundSecondary
    // ...
    Text { color: Theme.palette.text }
}
```

Available components: `LogosButton`, `LogosTextField`, `LogosText`, `LogosTabButton`.

Available theme tokens via `Theme.palette`:
- Colors: `background`, `backgroundSecondary`, `backgroundMuted`, `text`, `textMuted`, `border`, `overlayOrange`
- Spacing: `Theme.spacing.radiusSmall`, `Theme.spacing.radiusXlarge`
- Typography: `Theme.typography.secondaryText`, `Theme.typography.weightMedium`

> **Note:** `Logos.Theme` and `Logos.Controls` are only available when running inside `logos-basecamp`. They are not available in `logos-standalone-app`. Use them only if you know your module will run in basecamp, or guard the import.

---

## Step 7: Load in `logos-basecamp`

### 7.1 Create LGX packages

Bundle both modules as portable LGX files:

```bash
# Package calc_module (from Part 1)
cd ../logos-calc-module
nix bundle --bundler 'github:logos-co/nix-bundle-lgx#portable' '.#lib' -o lgx-calc-module
cd ../logos-calc-ui

# Package the QML UI plugin
nix bundle --bundler 'github:logos-co/nix-bundle-lgx#portable' '.' -o lgx-calc-ui
```

### 7.2 Install via logos-basecamp UI

1. Open `logos-basecamp`
2. Go to **Package Manager**
3. Click **Install from file**
4. Select `lgx-calc-module/*.lgx` — installs `calc_module`
5. Repeat for `lgx-calc-ui/*.lgx` — installs `calc_ui`

The "Calculator UI" tab appears in the sidebar. Clicking it loads your `Main.qml`.

### 7.3 Install via CLI (alternative)

```bash
nix build 'github:logos-co/logos-package-manager-module#cli' --out-link ./pm
./pm/bin/lgpm install --file lgx-calc-module/*.lgx
./pm/bin/lgpm install --file lgx-calc-ui/*.lgx
```

### 7.4 Build logos-basecamp from source

Build a local `logos-basecamp` binary, then use `lgpm` to populate a modules directory and run it:

```bash
# Build logos-basecamp
nix build 'github:logos-co/logos-basecamp' -o basecamp-result

# Create module directories
mkdir -p modules ui-plugins

# Build lgpm CLI
nix build 'github:logos-co/logos-package-manager-module#cli' --out-link ./pm

# Install capability_module (required by all UI plugins)
nix bundle --bundler 'github:logos-co/nix-bundle-lgx' \
  'github:logos-co/logos-capability-module' -o lgx-capability
./pm/bin/lgpm --modules-dir ./modules install --file lgx-capability/*.lgx

# Bundle and install calc_module (local, not portable)
cd ../logos-calc-module
nix bundle --bundler 'github:logos-co/nix-bundle-lgx' '.#lib' -o lgx-calc-module-local
cd ../logos-calc-ui
./pm/bin/lgpm --modules-dir ./modules install --file ../logos-calc-module/lgx-calc-module-local/*.lgx

# Bundle and install the QML UI plugin
nix bundle --bundler 'github:logos-co/nix-bundle-lgx' '.' -o lgx-calc-ui-local
./pm/bin/lgpm --modules-dir ./ui-plugins install --file lgx-calc-ui-local/*.lgx

# Run basecamp with the populated directories
./basecamp-result/bin/logos-basecamp \
  --modules-dir ./modules \
  --ui-plugins-dir ./ui-plugins
```

> **Local vs portable:** A locally-built `logos-basecamp` (via `nix build`) expects **local** `.lgx` packages (built without `#portable`). Portable builds (AppImage, macOS app bundle) expect **portable** `.lgx` packages.

### 7.5 Live reloading

For rapid iteration on QML, use development mode. This watches your source files and reloads on change:

```bash
QML_UI=$(pwd) logos-basecamp
```

Edit `Main.qml`, save, and the UI updates without rebuilding.

### 7.6 Testing without `logos-basecamp`

You can open `Main.qml` in any QML viewer (e.g., `qml` from Qt) to test the layout. The `logos` bridge won't be available, so clicking buttons will show "Logos bridge not available" — but you can verify the layout and styling work correctly.

```bash
# If you have Qt installed
qml Main.qml
```

---

## Step 8: Package for Distribution (Optional)

The LGX packages created in Step 7.2 are **local** packages — they contain `/nix/store` references and work on the machine that built them. To create **portable** packages for distribution to other machines, use the `#portable` bundler:

```bash
# Portable core module
cd ../logos-calc-module
nix bundle --bundler 'github:logos-co/nix-bundle-lgx#portable' '.#lib' -o lgx-portable

# Portable QML UI plugin
cd ../logos-calc-ui
nix bundle --bundler 'github:logos-co/nix-bundle-lgx#portable' '.' -o lgx-portable
```

Portable LGX packages are fully self-contained and can be installed on any machine with the Logos Package Manager:

```bash
nix build 'github:logos-co/logos-package-manager-module#cli' --out-link ./pm
./pm/bin/lgpm --modules-dir ./modules install --file calc_module.lgx
./pm/bin/lgpm --modules-dir ./ui-plugins install --file calc_ui.lgx
```

> **Local vs portable:** Local builds of `logos-basecamp` (via `nix build`) expect **local** `.lgx` packages. Portable builds (AppImage, macOS app bundle) expect **portable** `.lgx` packages. See the [logos-basecamp README](https://github.com/logos-co/logos-basecamp/blob/master/README.md) for details.

---

## Recap

| | Core Module (Part 1) | QML UI Plugin (Part 2) |
|---|---|---|
| Language | C++ | QML / JavaScript |
| Files | `.cpp`, `.h`, `CMakeLists.txt`, `module.yaml` | `Main.qml`, `metadata.json` |
| Compilation | Yes (CMake → `.so`) | No (file copy) |
| `metadata.type` | `"core"` | `"ui_qml"` |
| Test command | `logoscore -m ./result/lib -l calc_module` | `nix run .` |
| Calls other modules | Via `LogosAPI*` (C++) | Via `logos.callModule()` (JS) |

---

## What's Next

- **Add more methods** to `calc_module` and call them from QML
- **Use Logos Design System** styled components for consistent look and feel
- **Build a C++ UI module** for cases where QML sandboxing is too restrictive — see [Developer Guide](logos-developer-guide.md), Section 7.2
