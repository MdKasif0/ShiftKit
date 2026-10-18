const fs = require("fs");
const path = require("path");
const postcss = require("postcss");
const tailwind = require("@tailwindcss/postcss");

async function compileCss() {
  const root = path.resolve(__dirname, "..");
  const inputPath = path.join(root, "src", "app", "globals.css");
  const outputPath = path.join(root, "src", "app", "compiled.css");

  const css = fs.readFileSync(inputPath, "utf8");
  const result = await postcss([tailwind]).process(css, {
    from: inputPath,
    to: outputPath,
  });

  fs.writeFileSync(outputPath, result.css);
  console.log(`[ShiftKit CSS] Successfully compiled ${result.css.length} bytes of CSS to ${outputPath}`);
}

compileCss().catch((err) => {
  console.error("[ShiftKit CSS] Compilation failed:", err);
  process.exit(1);
});
