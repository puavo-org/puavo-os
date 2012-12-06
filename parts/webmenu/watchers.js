
console.info("Dev tools Starting!", process.argv);

require("yalr")({
  path: "content",
  ignore: "*.styl"
});

require("grunt").tasks("watch");
