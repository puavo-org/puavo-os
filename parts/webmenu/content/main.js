
function log(msg) {
  var e = new Event("log");
  e.msg = msg;
  window.dispatchEvent(e);
}

window.onblur = function() {
  log("blur!!");
  window.dispatchEvent(new Event("focusout"));
};

window.onmouseout = function() {
  log("mouseout!");
};

window.onload = function() {
  var close = document.querySelectorAll(".close")[0];
  close.addEventListener("click", function(){
    window.dispatchEvent(new Event("hide"));
  }, false);
};
