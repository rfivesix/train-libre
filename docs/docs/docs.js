/**
 * Train Libre Documentation Client Interactions
 * Handles KaTeX math rendering, Mermaid diagram rendering, theme switching,
 * mobile sidebar toggle, search filtering, copy-to-clipboard, and TOC scroll-spy.
 */

document.addEventListener("DOMContentLoaded", () => {
  // 1. KaTeX Auto-render
  if (typeof renderMathInElement !== "undefined") {
    renderMathInElement(document.body, {
      delimiters: [
        { left: "$$", right: "$$", display: true },
        { left: "$", right: "$", display: false },
      ],
      throwOnError: false,
    });
  }

  // 2. Mermaid.js Diagram Initialization
  if (typeof mermaid !== "undefined") {
    const isDark = document.documentElement.getAttribute("data-theme") !== "light";
    mermaid.initialize({
      startOnLoad: true,
      theme: isDark ? "dark" : "default",
      themeVariables: isDark
        ? {
            darkMode: true,
            background: "#151815",
            primaryColor: "#1b1f1b",
            primaryTextColor: "#f4f6f4",
            primaryBorderColor: "rgba(221, 255, 0, 0.4)",
            lineColor: "#ddff00",
            secondaryColor: "#151815",
            tertiaryColor: "#0e100e",
          }
        : {},
    });
  }

  // 3. Theme Toggle Interaction
  const themeBtn = document.getElementById("theme-toggle");
  if (themeBtn) {
    themeBtn.addEventListener("click", () => {
      const current = document.documentElement.getAttribute("data-theme") === "dark" ? "light" : "dark";
      document.documentElement.setAttribute("data-theme", current);
      localStorage.setItem("theme", current);
      if (typeof mermaid !== "undefined") {
        const mNodes = document.querySelectorAll(".mermaid");
        if (mNodes.length > 0) {
          mNodes.forEach((node) => {
            if (node.hasAttribute("data-mermaid")) {
              node.removeAttribute("data-processed");
              node.innerHTML = node.getAttribute("data-mermaid");
            }
          });
          mermaid.initialize({
            startOnLoad: false,
            theme: current === "light" ? "default" : "dark",
          });
          mermaid.run();
        }
      }
    });
  }

  // 4. Mobile Sidebar Toggle
  const sidebarToggle = document.getElementById("sidebar-toggle");
  const sidebar = document.getElementById("docs-sidebar");
  if (sidebarToggle && sidebar) {
    sidebarToggle.addEventListener("click", () => {
      const expanded = sidebar.classList.toggle("open");
      sidebarToggle.setAttribute("aria-expanded", expanded);
    });

    document.addEventListener("click", (e) => {
      if (
        sidebar.classList.contains("open") &&
        !sidebar.contains(e.target) &&
        !sidebarToggle.contains(e.target)
      ) {
        sidebar.classList.remove("open");
        sidebarToggle.setAttribute("aria-expanded", "false");
      }
    });
  }

  // 5. Sidebar Filter / Search
  const filterInput = document.getElementById("sidebar-filter");
  if (filterInput) {
    filterInput.addEventListener("input", (e) => {
      const val = e.target.value.toLowerCase().trim();
      document.querySelectorAll(".sidebar-nav-list li").forEach((li) => {
        const text = li.textContent.toLowerCase();
        li.style.display = text.includes(val) ? "" : "none";
      });
      document.querySelectorAll(".sidebar-group").forEach((group) => {
        const hasVisible = Array.from(group.querySelectorAll("li")).some(
          (li) => li.style.display !== "none"
        );
        group.style.display = hasVisible ? "" : "none";
      });
    });
  }

  // 6. Code Block Copy Button Delegation
  document.addEventListener("click", (e) => {
    const btn = e.target.closest(".copy-btn");
    if (!btn) return;
    const wrapper = btn.closest(".code-block-wrapper");
    if (wrapper) {
      const code = wrapper.querySelector("code");
      if (code) {
        navigator.clipboard.writeText(code.innerText);
        btn.textContent = "Copied!";
        setTimeout(() => {
          btn.textContent = "Copy";
        }, 1500);
      }
    }
  });

  // 7. Scroll-spy for Table of Contents
  const tocItems = document.querySelectorAll(".toc-list a");
  if (tocItems.length > 0) {
    const headingElements = Array.from(tocItems)
      .map((a) => {
        const id = a.getAttribute("href").substring(1);
        return document.getElementById(id);
      })
      .filter(Boolean);

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const id = entry.target.getAttribute("id");
            tocItems.forEach((a) => {
              if (a.getAttribute("href") === "#" + id) {
                a.classList.add("active");
              } else {
                a.classList.remove("active");
              }
            });
          }
        });
      },
      { rootMargin: "0px 0px -70% 0px", threshold: 0.1 }
    );

    headingElements.forEach((h) => observer.observe(h));
  }
});
