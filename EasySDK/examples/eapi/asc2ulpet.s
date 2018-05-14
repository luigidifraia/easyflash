        !to "asc2ulpet.ct", plain	; no load address
        * = 0        	; pc = table index
        ; first create "as-is" table
        !for i, 0, 255 {!byte i}
        ; now exchange upper and lower case characters
        * = 65, overlay
        !for i, 1, 26 {!byte * + 32}
        * = 97, overlay
        !for i, 1, 26 {!byte * - 32}