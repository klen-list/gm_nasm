# ⚙ gm_nasm
This is a set of Garry's Mod modules written by me **mostly under linux32 (elf_i386) srcds** on Netwide Assembler for fun and experience in assembler.

## 💾 Modules:
- **gmsv_hello_linux**: The simplest example. Outputs `Hello from Netwide Assembler!` to the console at startup.
- **gmsv_crc32_linux**: Example with adding a own function to the lua global table.  
The `CRC-32` algorithm is implemented as an function example.  
Instead of declaring a ready **CRC Table**, it is generated in runtime by poly `0xEDB88320`.  
Function: `number CRC32(string stringToChecksum)`. Btw this is **much faster** than `util.CRC`.  
- *Something else in the future (if I write more)*  

## 🔨 Build:
1) Install `nasm`: `sudo apt install nasm`
2) Copy `lua_shared_srv.so` from srcds folder to this folder (where Makefile)  
*Tip: file location in srcds: `Steam\steamapps\common\GarrysModDS\garrysmod\bin\lua_shared_srv.so`*
3) Run `make`

## 🚀 Run:
1) Copy dll's from folder to `lua/bin` folder of srcds  
*Tip: lua binary location in srcds: `Steam\steamapps\common\GarrysModDS\garrysmod\lua\bin`*
3) Change (or add) top line in `GarrysModDS\srcds_run`:  
*Note: this is to ensure that the dynamic linker finds all necessary dependencies when loading the module*  
```sh
export LD_LIBRARY_PATH=".:bin:garrysmod/bin:$LD_LIBRARY_PATH"
```
3) Run modules in game!
```lua
lua_run require"hello" require"crc32"
```
