unit DepackIO;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
interface

// Compression algorithm: RDC
// Algorithm developed by Ed Ross
function RDC_decompress(var source,dest; size: Word): Word; cdecl; external name 'DEPACKIO____RDC_DECOMPRESS_formal_formal_WORD__WORD';

// Compression algorithm: LZSS
// Algorithm developed by Lempel-Ziv-Storer-Szymanski
function LZSS_decompress(var source,dest; size: Word): Word; cdecl; external name 'DEPACKIO____LZSS_DECOMPRESS_formal_formal_WORD__WORD';

// Compression algorithm: LZW
// Algorithm developed by Lempel-Ziv-Welch
function LZW_decompress(var source,dest): Word; cdecl; external name 'DEPACKIO____LZW_DECOMPRESS_formal_formal__WORD';

// Compression algorithm: SixPack
// Algorithm developed by Philip G. Gage
function SIXPACK_decompress(var source,dest; size: Word): Word; cdecl; external name 'DEPACKIO____SIXPACK_DECOMPRESS_formal_formal_WORD__WORD';

// Compression algorithm: aPack
// Algorithm developed by Joergen Ibsen
function APACK_decompress(var source,dest): Dword; cdecl; external name 'DEPACKIO____APACK_DECOMPRESS_formal_formal__LONGWORD';

implementation

end.
