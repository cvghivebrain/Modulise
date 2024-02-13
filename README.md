# Modulise
__Modulise__ breaks up data into smaller chunks and compresses them separately. These chunks can be buffered to RAM and copied to VRAM one per frame. It was designed for Mega Drive games but could be used for anything, and is based on the idea behind the [Kosinski Moduled](https://segaretro.org/Kosinski_compression#Kosinski_Moduled_compression) format.

## Usage
<pre>modulise.exe {compressor} {module_size} {input_file} {output_file}</pre>
Remember to use quotes if your files have spaces in them.

The output file comprises the following parts:
* Two bytes displaying the number of modules (minus 1).
* Index of modules, each entry is two bytes showing the address of each module within the file.
* Two bytes displaying the size of the final module.
* The modules themselves.

<pre>modulise.exe {compressor} {module_size} {input_file} {output_file} -s</pre>
Add `-s` to use a short header as in the original Kosinski Moduled format.

The output file with short header comprises the following parts:
* Two bytes displaying the number of modules (minus 1) in the upper nybble, and the size of the final module in the lower 3 nybbles.
* The modules themselves.

Additional options are as follows:

* `-noindex` - omit the offset index.
* `-nolast` - omit the final module size.
* `-aligneven` - ensure all modules are aligned to an even address.
* `-actualcount` - first two bytes (or nybble in short header) shows the actual number of modules, not minus 1.