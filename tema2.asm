extern puts
extern printf
extern strlen
extern strstr

section .data
    filename: db "./input.dat",0
    inputlen: dd 2263
    fmtstr: db "Key: %d",0xa,0

section .text
    global main

;-------------------------------------------------------------
; This procedure receives two pointers to two strings and the
; size of both strings via the stack. It applies XOR between
; one byte from the first string and one byte from the second
; string. The result overwrites the first string.
;-------------------------------------------------------------
xor_strings:
    push ebp                ; saves stack state
    mov ebp, esp

    mov ebx, [ebp + 8]      ; source
    mov edx, [ebp + 12]     ; key
    mov ecx, [ebp + 16]     ; strings' length

xor_strings_loop:
    mov ah, byte [ebx + (ecx - 1)]  ; byte from the source
    mov al, byte [edx + (ecx - 1)]  ; byte from the key
    xor ah, al                      ; xors the two bytes
    mov [ebx + (ecx - 1)], ah       ; overwrites the source with the result

    dec ecx                 ; goes to the next character
    cmp ecx, 0              ; repeats until end of strings
    jnz xor_strings_loop

xor_strings_end:
    leave                   ; restores stack
    ret                     ; exits function

;-------------------------------------------------------------
; This procedure receives a pointer to a string and the size
; of it via the stack. It applies XOR between a byte and its
; predecessor. The result overwrites original string.
;-------------------------------------------------------------
rolling_xor:
    push ebp                ; saves stack state
    mov ebp, esp

    mov ebx, [ebp + 8]      ; string to be decoded
    mov ecx, [ebp + 12]     ; string's length

    xor edx, edx            ; index for characters' positions

    ; Put chars on stack in the order they are found
put_char_on_stack_loop:
    mov al, byte [ebx + edx]; copies char to al
    push eax                ; adds char to stack
    inc edx                 ; goes to next char
    cmp ecx, edx            ; repeats until end of string
    jnz put_char_on_stack_loop

    ; Applies Rolling XOR
    pop eax                 ; gets last char from string
rolling_xor_loop:
    pop edx                     ; gets next char
    xor eax, edx                ; xors the two chars
    mov [ebx + (ecx - 1)], al   ; overwrites the source with the result
    mov eax, edx                ; copies current char to be used next step

    dec ecx                 ; goes to next char
    cmp ecx, 1              ; repeats until start of string
    jnz rolling_xor_loop

rolling_xor_end:
    leave                   ; restores stack
    ret                     ; exits function

;-------------------------------------------------------------
; This procedure receives two ASCII characters via the stack.
; It converts from ASCII hexadecimal to decimal. The result
; overwrites the original values.
;-------------------------------------------------------------
ascii_to_number_16:
    push ebp                ; saves stack pointer
    mov ebp, esp

    mov eax, [ebp + 8]      ; char to be converted

ascii_to_number_16_check_al:
    cmp al, 0x61            ; checks if al is digit
    jb is_digit_al

is_letter_al:
    sub al, 0x57            ; substracts letter offset
    jmp ascii_to_number_16_check_ah

is_digit_al:
    sub al, 0x30            ; substracts digit offset

ascii_to_number_16_check_ah:
    cmp ah, 0x61
    jb is_digit_ah          ; checks if ah is digit

is_letter_ah:
    sub ah, 0x57            ; substracts letter offset
    jmp ascii_to_number_16_end

is_digit_ah:
    sub ah, 0x30            ; substracts digit offset

ascii_to_number_16_end:
    leave                   ; restores stack
    ret                     ; exits function

;-------------------------------------------------------------
; This procedure receives a pointer to an array and the size
; of it via the stack. The array should have only ASCII
; characters from hexadecimal. It converts characters to 
; their binary representaion. The size of the the array 
; decreases by half. The result overwrites the source and 
; replaces the rest of the array with null terminators.
;-------------------------------------------------------------
xor_hex_to_bin:
    push ebp                ; saves stack pointer
    mov ebp, esp

    mov ebx, [ebp + 8]      ; string to be converted
    mov ecx, [ebp + 12]     ; string length
    dec ecx

    xor esi, esi            ; counter for reading the values to be converted
    xor edi, edi            ; counter for placing the converted value

xor_hex_to_bin_loop:
    xor eax, eax
    mov ah, byte [ebx + esi]        ; first char
    mov al, byte [ebx + esi + 1]    ; second char

    ; Converts chars to their respective numbers in hexa
    push eax                ; numbers to be converted
    call ascii_to_number_16
    add esp, 4              ; restores stack

    shl ah, 4               ; multiplies first value with 16
    add al, ah              ; adds first value to the second one
    xor ah, ah              ; clears auxiliary register
    mov [ebx + edi], al     ; moves converted value to stack

    add esi, 2              ; increases first counter two times
    inc edi                 ; increases second counter

    cmp ecx, esi            ; repeats until end of string
    jnz xor_hex_to_bin_loop

    ; Deletes the remaining garbage chars
xor_hex_to_bin_del_garbage:
    mov [ebx + edi], byte 0x00  ; sets value to null
    inc edi                     ; goes to next character
    cmp ecx, edi                ; repeats until end of string
    jnz xor_hex_to_bin_del_garbage

xor_hex_to_bin_end:
    leave                   ; restores stack
    ret                     ; exits function

;-------------------------------------------------------------
; This procedure receives an ASCII character via the stack. 
; It converts the ASCII character to its number represen-
; tation in decimal. The result overwrites the original value.
;-------------------------------------------------------------
ascii_to_number_32:
    push ebp                ; saves stack pointer
    mov ebp, esp

    mov eax, [ebp + 8]      ; char to be converted

ascii_to_number_32_start:
    cmp al, 0x41            ; checks if char is digit
    jb is_digit_32

    jmp is_letter_32

is_digit_32:
    cmp al, 0x3d            ; checks if char is '='
    je is_equals_32

    sub al, 0x18            ; substract digit offset
    jmp ascii_to_number_32_end

is_letter_32:
    sub al, 0x41            ; substract letter offset
    jmp ascii_to_number_32_end

is_equals_32:
    xor eax, eax            ; sets the value to 0x00

ascii_to_number_32_end:
    leave                   ; restores stack
    ret                     ; exits function

;-------------------------------------------------------------
; This procedure receives a pointer to an array and the size
; of it via the stack. It moves the converted values to the 
; correct positions. The result overwrites the initial array.
;-------------------------------------------------------------
base32_move_offset:
    push ebp                ; saves stack pointer
    mov ebp, esp

    mov ebx, [ebp + 8]      ; string to be manipulated
    mov ecx, [ebp + 12]     ; string length

    mov esi, 8              ; source index
    mov edi, 5              ; destination index
    xor edx, edx            ; char index

base32_move_offset_loop:
    add esi, edx            ; adds offset to source
    mov eax, [ebx + esi]    ; copies char from source + offset to a 
                                ; temporary register
    sub esi, edx            ; substracts offset from source

    add edi, edx            ; adds offset to destination
    mov [ebx + edi], eax    ; coppies chara from source + offset to 
                                ; destination + offset
    sub edi, edx            ; substracts offset from destination

    inc edx                 ; goes to the next character
    cmp edx, 6              ; repeats the loop 5 times
    jnz base32_move_offset_loop

    xor edx, edx            ; clears character index
    add edi, 5              ; goes to next destination
    add esi, 8              ; goes to next source
    cmp ecx, esi            ; repeats until all sources are moved
    jnz base32_move_offset_loop

base32_move_offset_end:
    leave                   ; restores stack
    ret                     ; exits function

;-------------------------------------------------------------
; This procedure receives a pointer to an array and the size 
; of it via the stack. It decrypts the array from base 32.
; The result overwrites the first string.
;-------------------------------------------------------------
base32decode:
    push ebp                ; saves stack pointer
    mov ebp, esp

    mov ebx, [ebp + 8]      ; string to be converted
    mov ecx, [ebp + 12]     ; string length
    xor edi, edi            ; index used to copy 8 chars from string 
    xor esi, esi            ; counter from 0 to length
    xor eax, eax            ; auxiliary register
    xor edx, edx            ; stores first 4 bytes from the decoded string

base32decode_loop:
    mov edi, esi            ; copies value of the current index to edi
    add edi, 7              ; adds offset to get 8 bytes
    push ecx                ; saves the length of the string

push_val_to_stack_loop:
    xor ecx, ecx                ; stores last byte of the decoded string
    xor eax, eax                ; clears auxiliary register
    mov al, byte [ebx + edi]    ; gets byte in base 32

    ; Converts from base 32 to decimal number
    push eax                ; value to be converted
    call ascii_to_number_32
    add esp, 4              ; restores stack

    push eax                ; pushes converted value to stack

    dec edi                 ; goes to next character
    cmp edi, esi            ; repeats 8 times
    jns push_val_to_stack_loop

    ; Pops values from stack and forms the first 4 bytes
    pop eax                 ; gets converted value

    mov edx, eax            ; copies value to edx
    shl edx, 5              ; moves value 5 bits to the left

    ; Gets values from the stack and adds them to edx
    pop eax                 ; gets converted value
    add dl, al              ; copies value to edx
    shl edx, 5              ; moves value 5 bits to the left

    pop eax                 ; gets converted value
    add dl, al              ; copies value to edx
    shl edx, 5              ; moves value 5 bits to the left

    pop eax                 ; gets converted value
    add dl, al              ; copies value to edx
    shl edx, 5              ; moves value 5 bits to the left

    pop eax                 ; gets converted value
    add dl, al              ; copies value to edx
    shl edx, 5              ; moves value 5 bits to the left

    pop eax                 ; gets converted value
    add dl, al              ; copies value to edx
    shl edx, 2              ; moves value 2 bits to the left

    pop eax                 ; gets converted value
    mov ah, al              ; copies last value to ah
    shr ah, 3               ; deletes last 3 bits of ah
    add dl, ah              ; adds first 2 bits of second last number to 
                                ; end of edx
                            ; edx is now complete

    mov cl, al              ; copies last 3 bits of second last number
    shl cl, 5               ; moves value 5 bits to the left
    pop eax                 ; gets last number
    add cl, al              ; adds last number to ecx
                            ; cl is now complete

    ; Adds edx to the source
    mov [ebx + esi + 4], cl     ; adds byte from ecx to source

    mov [ebx + esi + 3], dl     ; adds last byte
    mov [ebx + esi + 2], dh     ; adds second last byte
    shr edx, 16                 ; deletes last 2 bytes of edx
    mov [ebx + esi + 1], dl     ; adds second byte
    mov [ebx + esi + 0], dh     ; adds first byte

    pop ecx                 ; restores length of string
    add esi, 8              ; goes to next 8 bytes

    cmp ecx, esi            ; repeat until end of string
    jnz base32decode_loop

    push ecx                ; saves length of the string

    ; Moves the converted values to the correct indexes
    push ecx                ; the length of the string
    push ebx                ; the source string
    call base32_move_offset
    add esp, 8              ; restores stack

    pop ecx                 ; restores length of the string

    mov esi, 62             ; index from where garbage is deleted
base32decode_del_garbage:
    mov [ebx + esi], byte 0x00  ; overwrites garbage with null terminator

    inc esi                 ; goes to next char
    cmp ecx, esi            ; repeats until end of string
    jnz base32decode_del_garbage

base32decode_end:
    leave                   ; restores stack
    ret                     ; exits function

;-------------------------------------------------------------
; This procedure receives a pointer to a string, a single 
; byte key, the length of the string, and a pointer to an
; array via the stack. It does logical XOR between each
; byte from the string and the key. The result is placed at
; the address of the array.
;-------------------------------------------------------------
xor_string_one_byte:
    push ebp                ; saves stack pointer
    mov ebp, esp

    mov ebx, [ebp + 8]      ; string to be converted
    mov ecx, [ebp + 12]     ; key
    mov esi, [ebp + 16]     ; string length
    mov edx, [ebp + 20]     ; string to put xorred values
    xor eax, eax            ; auxiliary register

    mov [edx + esi], byte 0x00  ; puts null terminator at the end of string

xor_string_one_byte_loop:
    xor eax, eax                    ; clears register
    mov al, byte [ebx + esi - 1]    ; gets byte to be xorred
    xor al, cl                      ; xors the byte with the key
    mov [edx + esi - 1], al         ; moves the result to edx

    dec esi                 ; goes to next char
    cmp esi, 0              ; repeat until end of string
    jnz xor_string_one_byte_loop

xor_string_one_byte_end:
    leave                   ; restores stack
    ret                     ; exits function

;-------------------------------------------------------------
; This procedure receives a pointer to a string, the length of
; it, and a poiner to an array via the stack. It calls
; xor_string_one_byte with all one byte possible keys and
; returns the decoded message which contains the string "force".
;-------------------------------------------------------------
bruteforce_singlebyte_xor:
    push ebp                ; saves stack pointer
    mov ebp, esp

    mov ebx, [ebp + 8]      ; string to be xorred
    mov ecx, [ebp + 12]     ; string length
    mov edx, [ebp + 16]     ; array to store xorred values

    mov edi, 0x100          ; first key to brute force

    push ebp                ; saves stack pointer
    mov ebp, esp

    ; Creates "force" string
    push byte "e"
    push dword "forc"
    mov esi, esp            ; copies "force" address to eax

bruteforce_singlebyte_xor_loop:
    dec edi                 ; goes to next key

    ; XORs the string's bytes with the key
    pushad                  ; saves all registers
    push edx                ; string to put xorred values
    push ecx                ; string length
    push edi                ; key
    push ebx                ; string to be converted
    call xor_string_one_byte
    add esp, 16             ; restores stack
    popad                   ; restores all registers

    ; Checks if there is "force" in the string
    push esi                ; saves string "force"
    push edx                ; saves string to put xorred values
    push ecx                ; saves string length
    push ebx                ; saves string to be converted

    push esi                ; the string "force"
    push edx                ; the xorred string
    call strstr
    add esp, 8              ; restores stack

    pop ebx                 ; restores string to be converted
    pop ecx                 ; restores string length
    pop edx                 ; restores string to put xorred values
    pop esi                 ; restores string "force"

    cmp eax, 0              ; repeats until "force" is found in string
    je bruteforce_singlebyte_xor_loop

bruteforce_singlebyte_xor_end:
    mov esp, ebp            ; restores stack
    pop ebp

    mov eax, edi            ; returns the key in register eax
    leave                   ; restores stack
    ret                     ; exits function


;-------------------------------------------------------------
; This procedure receives a pointer to an array via the stack.
; It fills the array with the English alphabet letters and
; their equivalent in the encrypted alphabet.
;-------------------------------------------------------------
create_substitution_table:
    push ebp                ; saves stack pointer
    mov ebp, esp

    mov edx, [ebp + 8]      ; substituion table

    ; Adds letters in the substitution table
    mov [edx +  0], word "aq"      ; a
    mov [edx +  2], word "br"      ; b
    mov [edx +  4], word "cw"      ; c
    mov [edx +  6], word "de"      ; d
    mov [edx +  8], word "e "      ; e
    mov [edx + 10], word "fu"      ; f
    mov [edx + 12], word "gt"      ; g
    mov [edx + 14], word "hy"      ; h
    mov [edx + 16], word "ii"      ; i
    mov [edx + 18], word "jo"      ; j
    mov [edx + 20], word "kp"      ; k
    mov [edx + 22], word "lf"      ; l
    mov [edx + 24], word "mh"      ; m
    mov [edx + 26], word "n."      ; n
    mov [edx + 28], word "og"      ; o
    mov [edx + 30], word "pd"      ; p
    mov [edx + 32], word "qa"      ; q
    mov [edx + 34], word "rs"      ; r
    mov [edx + 36], word "sl"      ; s
    mov [edx + 38], word "tk"      ; t
    mov [edx + 40], word "um"      ; u
    mov [edx + 42], word "vj"      ; v
    mov [edx + 44], word "wn"      ; w
    mov [edx + 46], word "xb"      ; x
    mov [edx + 48], word "yz"      ; y
    mov [edx + 50], word "zv"      ; z
    mov [edx + 52], word " c"      ; space
    mov [edx + 54], word ".x"      ; full stop
    mov [edx + 56], byte 0x00      ; null terminal

create_substitution_table_end:
    leave                   ; restores stack
    ret                     ; exits function

;-------------------------------------------------------------
; This procedure receives a pointer to a string, its length, 
; and a pointer to a substitution table. It replaces all
; letters in the string with their equivalent in the substi-
; tution string. The result overwrites the first string.
;-------------------------------------------------------------
break_substitution:
    push ebp                ; saves stack pointer
    mov ebp, esp

    mov ebx, [ebp + 8]      ; string 6
    mov ecx, [ebp + 12]     ; string 6 length
    mov edx, [ebp + 16]     ; substitution table
    xor eax, eax            ; stores the current char from string 6
    xor esi, esi            ; counter for substitution table
    xor edi, edi            ; counter for string 6

break_substitution_loop:
    mov al, [ebx + edi]     ; gets current char from string 6

    mov esi, -1             ; sets counter for substitution table
find_in_table_loop:
    add esi, 2              ; goes to next char in substitution table
    cmp [edx + esi], al     ; repeats until chara is found in substitution table
    jne find_in_table_loop

    mov al, [edx + esi - 1] ; copies decoded char to al
    mov [ebx + edi], al     ; overwrites the current character with the 
                                ; decoded one

    inc edi                 ; goes to next char in string 6
    cmp ecx, edi            ; repeats until end of string
    jnz break_substitution_loop
    
break_substitution_end:
    leave                   ; restores stack
    ret                     ; exits function


;-------------------------------------------------------------
; The main body of the function. It loads the input from 
; "input.dat" file, applies the convertions to the respec-
; tive parts, and prints to the standard output the decoded
; messages.
;-------------------------------------------------------------
main:
    push ebp
    mov ebp, esp
    sub esp, 2300
    
    ; fd = open("./input.dat", O_RDONLY);
    mov eax, 5
    mov ebx, filename
    xor ecx, ecx
    xor edx, edx
    int 0x80
    
    ; read(fd, ebp-2300, inputlen);
    mov ebx, eax
    mov eax, 3
    lea ecx, [ebp-2300]
    mov edx, [inputlen]
    int 0x80

    ; close(fd);
    mov eax, 6
    int 0x80

    ; all input.dat contents are now in ecx (address on stack)

    ; TASK 1: Simple XOR between two byte streams------------------------------

    mov ebx, ecx        ; copies string 1.1 address to ebx

    ; Calculates string 1.1 length
    push ecx            ; saves input address

    push ebx            ; string 1.1
    call strlen
    add esp, 4          ; restores stack
    pop ecx             ; restores input address

    ; Adds offset to get string 1.2 in edx
    inc eax             ; eax is the length of string 1.1
    add ecx, eax        ; adds offset to ecx
    mov edx, ecx        ; copies string 1.2 address to edx

    ; Adds offset to go over string 1.2
    add ecx, eax        ; adds offset for the second string

    ; XORs them byte by byte
    push ecx            ; saves input address

    push eax            ; strings length
    push edx            ; string 1.2 (key)
    push ebx            ; string 1.1 (string to convert)
    call xor_strings
    add esp, 12         ; restores stack
    pop ecx             ; restores input address

    ; Prints the first resulting string
    push ecx            ; saves input address

    push ebx            ; decoded string
    call puts
    add esp, 4          ; restores stack
    pop ecx             ; restores input address

    ; TASK 2: Rolling XOR------------------------------------------------------

    mov ebx, ecx        ; copies string 2 to ebx

    ; Calculates string 2 length
    push ecx            ; saves input address

    push ebx            ; string 2
    call strlen
    add esp, 4          ; restores stack
    pop ecx             ; restores input address

    inc eax             ; eax is the length of string 2
    add ecx, eax        ; adds offset to go over string 2

    ; Applies rolling XOR
    dec eax
    push ecx            ; saves input address

    push eax            ; string 2 length
    push ebx            ; string to be decoded
    call rolling_xor
    add esp, 8          ; restores stack
    pop ecx             ; restores input address

    ; Print the second resulting string
    push ecx            ; saves input address

    push ebx            ; decoded string
    call puts
    add esp, 4          ; restores stack
    pop ecx             ; restores input address

    
    ; TASK 3: XORing strings represented as hex strings------------------------

    mov ebx, ecx        ; copies string 3.1 address to ebx

    ; Calculates string 3.1 length
    push ecx            ; saves input address

    push ebx            ; string 3.1
    call strlen
    add esp, 4          ; restores stack
    pop ecx             ; restores input address

    ; Adds offset to get string 3.2 in edx
    inc eax             ; eax is the length of string 3.1
    add ecx, eax        ; adds offset to ecx
    mov edx, ecx        ; copies string 3.2 address to edx

    ; Adds offset to go over string 3.2
    add ecx, eax        ; adds offset for the second string

    ; Converts string 3.1 from hex to binary
    push eax            ; saves string 3.1 length
    push ecx            ; saves input address

    push eax            ; string 3.1 length
    push ebx            ; string 3.1
    call xor_hex_to_bin
    add esp, 8          ; restores stack
    pop ecx             ; restores input address
    pop eax             ; restores string 3.1 length

    ; Converts string 3.2 from hex to binary
    push ebx            ; saves string 3.1 address
    push eax            ; saves string 3.1 length
    push ecx            ; saves input address

    push eax            ; string 3.2 length
    push edx            ; string 3.2
    call xor_hex_to_bin
    add esp, 8          ; restores stack
    pop ecx             ; restores input address
    pop eax             ; restores string 3.1 length
    pop ebx             ; restores string 3.1 address

    ; XORs them byte by byte
    push ecx            ; saves input address

    push eax            ; strings length
    push edx            ; string 3.2
    push ebx            ; string 3.1
    call xor_strings
    add esp, 12         ; restores stack
    pop ecx             ; restores input address

    ; Prints the third string
    push ecx            ; saves input address
    push ebx            ; decoded string
    call puts
    add esp, 4          ; restores stack
    pop ecx             ; restores input address
    
    ; TASK 4: decoding a base32-encoded string---------------------------------

    mov ebx, ecx        ; copies string 4 address to ebx

    ; Calculates string 4 length
    push ecx            ; saves input address

    push ebx            ; string 4
    call strlen
    add esp, 4          ; restores stack
    pop ecx             ; restores input address

    ; Adds offset to go over string 4
    inc eax             ; eax is the length of string 4
    add ecx, eax        ; adds offset to ecx
    dec eax             ; reverts to the original value

    ; Decodes from base 32
    push ecx            ; saves input address

    push eax            ; string 4 length
    push ebx            ; string 4
    call base32decode
    add esp, 8          ; restores stack
    pop ecx             ; restores input address

    ; Print the fourth string
    push ecx            ; saves input address

    push ebx            ; decoded string
    call puts
    add esp, 4          ; restores stack
    pop ecx             ; restores input address

    ; TASK 5: Find the single-byte key used in a XOR encoding------------------

    ; Allocates memory for new array
    push ebp            ; saves stack counters
    mov ebp, esp
    sub esp, 75         ; allocates memory for a new array to store the xorred
                            ; values
    lea edx, [ebp - 75] ; loads array's address to edx

    mov ebx, ecx        ; copies string 5 address to ebx

    ; Calculates string 5 length
    push edx            ; saves array address
    push ecx            ; saves input address

    push ebx            ; string 5
    call strlen
    add esp, 4          ; restores stack
    pop ecx             ; restores input address
    pop edx             ; restores array address

    inc eax             ; adds null terminator to string length
    add ecx, eax        ; adds offset to go over string 5
    dec eax             ; reverts to original size

    ; Finds the key
    push ecx            ; saves array address

    push edx            ; array to store the xorred values
    push eax            ; string 5 length
    push ebx            ; string 5
    call bruteforce_singlebyte_xor
    add esp, 12         ; restores stack
    pop ecx             ; restores input address

    ; Prints the fifth string
    push eax
    push ecx            ; saves input address

    push edx            ; decoded string
    call puts
    add esp, 4          ; restores stack
    pop ecx             ; restores input address
    pop eax

    ; Prints the found key value
    push ecx            ; saves input address

    push eax            ; key
    push fmtstr         ; format string
    call printf
    add esp, 8          ; restores stack
    pop ecx             ; restores input address

    mov esp, ebp        ; restores stack from adding auxiliary array
    pop ebp

    ; TASK 6: Break substitution cipher----------------------------------------

    mov ebx, ecx        ; copies string 6 address to ebx

    ; Allocates memory for new array
    push ebp            ; saves stack counters
    mov ebp, esp
    sub esp, 60         ; allocates memory for a new array to store the
                            ; substitution table
    lea edx, [ebp - 60] ; loads array's address to edx

    ; Calculates string 6 length
    push edx            ; saves substitution table

    push ebx            ; string 6
    call strlen
    add esp, 4          ; restores stack
    pop edx             ; restores substitution table

    ; Creates substitution table
    push edx            ; empty substitution table
    call create_substitution_table
    add esp, 4          ; restores stack

    ; Breaks substitution
    push edx            ; saves substitution table
    push ebx            ; saves string 6

    push edx            ; substituion table
    push eax            ; string 6 length
    push ebx            ; string 6
    call break_substitution
    add esp, 12         ; restores stack
    pop ebx             ; restores string 6
    pop edx             ; restores substitution table

    ; Print final solution (after some trial and error)
    push edx            ; saves substitution table

    push ebx            ; decoded string
    call puts
    add esp, 4          ; restores stack
    pop edx             ; resores substitution table

    ; Print substitution table
    push edx            ; substituion table
    call puts
    add esp, 4          ; restores stack

    mov esp, ebp        ; restores stack from adding substituion table
    pop ebp

    ; Phew, finally done
    ; Omae wa mou shindeiru!

    xor eax, eax
    leave
    ret
