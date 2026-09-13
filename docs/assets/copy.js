// Adds a "Copy" button to every code block. Purely additive: every code
// block is already plain, selectable text without this script, so a
// browser with JavaScript disabled loses nothing but the button.
(function () {
  document.querySelectorAll("pre").forEach(function (pre) {
    var wrapper = document.createElement("div");
    wrapper.className = "code-block";
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);

    var btn = document.createElement("button");
    btn.className = "copy-btn";
    btn.type = "button";
    btn.textContent = "Copy";
    wrapper.appendChild(btn);

    btn.addEventListener("click", function () {
      var text = pre.textContent.replace(/^\$ /gm, "");
      navigator.clipboard.writeText(text).then(
        function () {
          btn.textContent = "Copied";
          setTimeout(function () {
            btn.textContent = "Copy";
          }, 1500);
        },
        function () {
          btn.textContent = "Select + Ctrl/Cmd-C";
          setTimeout(function () {
            btn.textContent = "Copy";
          }, 2000);
        }
      );
    });
  });
})();
