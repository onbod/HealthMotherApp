import type { Config } from "tailwindcss"

const config: Config = {
  darkMode: ["class"],
  content: [
    "./pages/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./app/**/*.{ts,tsx}",
    "./src/**/*.{ts,tsx}",
    "*.{js,ts,jsx,tsx,mdx}",
  ],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        // Maternal Health Color Palette
        maternal: {
          // Soft Blues - Tranquility, Serenity, Peace
          "blue-50": "#f0f8ff",
          "blue-100": "#e0f2fe",
          "blue-200": "#bae6fd",
          "blue-300": "#7dd3fc",
          "blue-400": "#38bdf8",
          "blue-500": "#0ea5e9",
          "blue-600": "#0284c7",
          "blue-700": "#0369a1",

          // Soft Greens - Growth, Health, Nature
          "green-50": "#f0fdf4",
          "green-100": "#dcfce7",
          "green-200": "#bbf7d0",
          "green-300": "#86efac",
          "green-400": "#4ade80",
          "green-500": "#22c55e",
          "green-600": "#16a34a",
          "green-700": "#15803d",

          // Light Browns - Stability, Grounding, Security
          "brown-50": "#fdf8f6",
          "brown-100": "#f2e8e5",
          "brown-200": "#eaddd7",
          "brown-300": "#e0cfc5",
          "brown-400": "#d2bab0",
          "brown-500": "#bfa094",
          "brown-600": "#a18072",
          "brown-700": "#8b6f47",
        },
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config

export default config
