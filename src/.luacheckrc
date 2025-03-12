std = "lua51c+luajit"
ignore = {
   "212",  -- unused argument 'self'
   "631"  -- line is too long
}

globals = {
   "require",
   "mobdebug",
   "_CONSOLE",
   "_DEBUG",
   "_IS_LOVEJS",
   "love",
   "class",
   "types",
   "inspect",
   "fun",
   "_ppr",
   "utf8",
   "help",
   "pause",

   math = {
      fields = {
         "clamp"
      }
   },
   string = {
      fields = {
         "split"
      }
   },
   table = {
      fields = {
         "unpack"
      }
   },
}

files["mod/**/*.lua"] = {
   globals = {
      "data",
      "save",
      "config",
      "_MOD_ID",
   }
}
files["scratch/**/*.lua"].globals = files["mod/**/*.lua"].globals
files["scratch/**/*.lua"].ignore = {
   "111", -- setting non-standard global variable 'X'
}

local test = {
   globals = {
      "save",
      "config",
      "disable"
   },
   ignore = {
      "111", -- setting non-standard global variable 'X'
   }
}
files["test/**/*.lua"] = test
files["**/mod/*/test/**/*.lua"] = test

files["**/locale/**/*.lua"] = {ignore = {"212"}}

stds.i18n_jp = {
   globals = {
      "get",

      "you",
      "name",
      "basename",
      "itemname",
      "ordinal",
      "he",
      "his",
      "him",

      "kare_wa",
      "aru",
      "u",
      "ka",
      "ga",
      "kimi",
      "ore",
      "kana",
      "kure",
      "ta",
      "da",
      "dana",
      "daro",
      "tanomu",
      "noda",
      "yo",
      "na",
      "ru",
      "thanks",
      "nii",
      "syujin"
   }
}

files["**/locale/jp/**/*.lua"].std = "+i18n_jp"
files["**/locale/jp/*.lua"].std = "+i18n_jp"

stds.i18n_en = {
   globals = {
      "get",

      "you",
      "name",
      "basename",
      "itemname",
      "ordinal",
      "he",
      "his",
      "him",

      "s",
      "is",
      "have",
      "does",
      "his_owned",
      "himself",
      "trim_job",
      "name_nojob",
      "capitalize",
      "plural"
   }
}

files["**/locale/en/**/*.lua"].std = "+i18n_en"
files["**/locale/en/*.lua"].std = "+i18n_en"
