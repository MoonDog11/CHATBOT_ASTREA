// eslint.config.mjs
import globals from "globals";
import pluginJs from "@eslint/js";
import pluginReact from "eslint-plugin-react";
import pluginNode from "eslint-plugin-node";

export default [
  {
    files: ["**/*.{js,mjs,cjs,jsx}"],
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },
      parserOptions: {
        ecmaVersion: 2021, // Ajusta según tus necesidades
        sourceType: "module",
      },
    },
    plugins: {
      react: pluginReact,
      node: pluginNode,
    },
    rules: {
      // Agrega reglas personalizadas aquí
      "no-undef": "error",
    },
    settings: {
      react: {
        version: "detect",
      },
    },
  },
  // Añade otras configuraciones si es necesario
];
