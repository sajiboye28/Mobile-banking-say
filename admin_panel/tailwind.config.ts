import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: "#eef2ff",
          100: "#e0e7ff",
          200: "#c7d2fe",
          300: "#a5b4fc",
          400: "#818cf8",
          500: "#6366f1",
          600: "#4f46e5",
          700: "#4338ca",
          800: "#3730a3",
          900: "#312e81",
          950: "#1e1b4b",
        },
        accent: {
          emerald: "#10b981",
          rose: "#f43f5e",
          amber: "#f59e0b",
          sky: "#0ea5e9",
        },
      },
      boxShadow: {
        glow: "0 0 15px -3px rgba(99, 102, 241, 0.4)",
        "glow-lg": "0 0 25px -5px rgba(99, 102, 241, 0.5)",
        "glow-emerald": "0 0 15px -3px rgba(16, 185, 129, 0.4)",
        "glow-rose": "0 0 15px -3px rgba(244, 63, 94, 0.4)",
        "glow-amber": "0 0 15px -3px rgba(245, 158, 11, 0.4)",
        glass: "0 8px 32px 0 rgba(31, 38, 135, 0.15)",
        "card-hover": "0 20px 40px -12px rgba(0, 0, 0, 0.15)",
      },
      backdropBlur: {
        xs: "2px",
      },
      animation: {
        "fade-in": "fadeIn 0.5s ease-out",
        "slide-up": "slideUp 0.5s ease-out",
        "slide-in-left": "slideInLeft 0.3s ease-out",
        shimmer: "shimmer 2s linear infinite",
      },
      keyframes: {
        fadeIn: {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        slideUp: {
          "0%": { opacity: "0", transform: "translateY(10px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        slideInLeft: {
          "0%": { opacity: "0", transform: "translateX(-10px)" },
          "100%": { opacity: "1", transform: "translateX(0)" },
        },
        shimmer: {
          "0%": { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        },
      },
    },
  },
  plugins: [],
};

export default config;
