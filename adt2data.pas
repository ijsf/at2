unit AdT2data;
{$S-,Q-,R-,V-,B-,X+}
{$PACKRECORDS 1}
{$i asmport.inc}
interface

const
  font8x16: array[0..1023] of Dword = (
    $00000000,$00000000,$00000000,$00000000,$71300000,$313131F1,$FC313131,$00000000,
    $CD780000,$31190DCD,$FCCDC161,$00000000,$29CE0000,$2E292929,$C8282828,$00000000,
    $19080000,$FDD97939,$3C191919,$00000000,$00000000,$06361C00,$BE32180C,$00000000,
    $00000000,$18181F00,$9E33031E,$00000000,$00000000,$28440000,$44281010,$00000000,
    $E7E70000,$E7E7E7E7,$E7E7E7E7,$000000E7,$FFFF0000,$C3C7CFDF,$FFDFCFC7,$000000FF,
    $38100000,$1010107C,$10387C10,$00000000,$00000000,$7E7E7E3C,$00003C7E,$00000000,
    $991F0000,$1818385F,$70793A1C,$00000000,$191F0000,$1818181F,$70783818,$00000000,
    $55555500,$55555555,$55555555,$00000055,$7F7F7F00,$7F7F7F7F,$7F7F7F7F,$0000007F,
    $60400000,$7E7C7870,$6070787C,$00000040,$06020000,$7E3E1E0E,$060E1E3E,$00000002,
    $38100000,$1010107C,$10001000,$00000000,$82FE0000,$32128282,$3070FE72,$00000010,
    $00000000,$AA000000,$00000000,$00000000,$28140000,$50505050,$14285050,$00000000,
    $14280000,$0A0A0A0A,$28140A0A,$00000000,$00100000,$10100010,$10387C10,$00000000,
    $38100000,$1010107C,$10101010,$00000000,$10100000,$10101010,$10387C10,$00000000,
    $00000000,$FF0E0C08,$00080C0E,$00000000,$00000000,$FF703010,$00103070,$00000000,
    $00000000,$3C3C1800,$00000018,$00000000,$F3FE0000,$81FFF3F3,$FF81FF81,$00000000,
    $00000000,$7C383810,$00FEFE7C,$00000000,$00000000,$7C7CFEFE,$00103838,$00000000,
    $00000000,$00000000,$00000000,$00000000,$3C180000,$18183C3C,$18180018,$00000000,
    $28282800,$00002828,$00000000,$00000000,$28000000,$28287C28,$28287C28,$00000000,
    $D67C1010,$167CD0D2,$7CD69616,$00001010,$00000000,$08C4C200,$86462010,$00000000,
    $6C380000,$DC76386C,$76CCCCCC,$00000000,$10101000,$00000020,$00000000,$00000000,
    $10080000,$20202020,$08102020,$00000000,$08100000,$04040404,$10080404,$00000000,
    $00000000,$FE385410,$00105438,$00000000,$00000000,$7C101000,$00001010,$00000000,
    $00000000,$00000000,$10101000,$00000020,$00000000,$7C000000,$00000000,$00000000,
    $00000000,$00000000,$10000000,$00000000,$00000000,$08040200,$80402010,$00000000,
    $6C380000,$D6D6C6C6,$386CC6C6,$00000000,$38180000,$18181878,$7E181818,$00000000,
    $C67C0000,$30180C06,$FEC6C060,$00000000,$C67C0000,$063C0606,$7CC60606,$00000000,
    $1C0C0000,$FECC6C3C,$1E0C0C0C,$00000000,$C0FE0000,$06FCC0C0,$7CC60606,$00000000,
    $60380000,$C6FCC0C0,$7CC6C6C6,$00000000,$C6FE0000,$180C0606,$30303030,$00000000,
    $C67C0000,$C67CC6C6,$7CC6C6C6,$00000000,$C67C0000,$067EC6C6,$780C0606,$00000000,
    $00000000,$00001000,$00001000,$00000000,$00000000,$00001000,$20101000,$00000000,
    $04000000,$40201008,$04081020,$00000000,$00000000,$00003C00,$0000003C,$00000000,
    $20000000,$02040810,$20100804,$00000000,$C67C0000,$18180CC6,$18180018,$00000000,
    $7C000000,$DEDEC6C6,$7CC0DCDE,$00000000,$38100000,$FEC6C66C,$C6C6C6C6,$00000000,
    $66FC0000,$667C6666,$FC666666,$00000000,$663C0000,$C0C0C0C2,$3C66C2C0,$00000000,
    $6CF80000,$66666666,$F86C6666,$00000000,$66FE0000,$68786862,$FE666260,$00000000,
    $66FE0000,$68786862,$F0606060,$00000000,$663C0000,$DEC0C0C2,$3A66C6C6,$00000000,
    $C6C60000,$C6FEC6C6,$C6C6C6C6,$00000000,$183C0000,$18181818,$3C181818,$00000000,
    $0C1E0000,$0C0C0C0C,$78CCCCCC,$00000000,$66E60000,$78786C66,$E666666C,$00000000,
    $60F00000,$60606060,$FE666260,$00000000,$EEC60000,$C6D6FEFE,$C6C6C6C6,$00000000,
    $E6C60000,$CEDEFEF6,$C6C6C6C6,$00000000,$C67C0000,$C6C6C6C6,$7CC6C6C6,$00000000,
    $66FC0000,$607C6666,$F0606060,$00000000,$C67C0000,$C6C6C6C6,$7CDED6C6,$00000E0C,
    $66FC0000,$6C7C6666,$E6666666,$00000000,$C67C0000,$0C3860C6,$7CC6C606,$00000000,
    $7E7E0000,$1818185A,$3C181818,$00000000,$C6C60000,$C6C6C6C6,$7CC6C6C6,$00000000,
    $C6C60000,$C6C6C6C6,$10386CC6,$00000000,$C6C60000,$D6D6C6C6,$6CEEFED6,$00000000,
    $C6C60000,$38387C6C,$C6C66C7C,$00000000,$66660000,$183C6666,$3C181818,$00000000,
    $C6FE0000,$30180C86,$FEC6C260,$00000000,$20380000,$20202020,$38202020,$00000000,
    $00000000,$20408000,$02040810,$00000000,$041C0000,$04040404,$1C040404,$00000000,
    $6C381000,$000000C6,$00000000,$00000000,$00000000,$00000000,$00000000,$0000FF00,
    $00081010,$00000000,$00000000,$00000000,$00000000,$7C0C7800,$76CCCCCC,$00000000,
    $60E00000,$666C7860,$7C666666,$00000000,$00000000,$C0C67C00,$7CC6C0C0,$00000000,
    $0C1C0000,$CC6C3C0C,$76CCCCCC,$00000000,$00000000,$FEC67C00,$7CC6C0C0,$00000000,
    $6C380000,$60F06064,$F0606060,$00000000,$00000000,$CCCC7600,$7CCCCCCC,$0078CC0C,
    $60E00000,$66766C60,$E6666666,$00000000,$18000000,$18183800,$3C181818,$00000000,
    $06000000,$06060E00,$06060606,$003C6666,$60E00000,$786C6660,$E6666C78,$00000000,
    $18380000,$18181818,$3C181818,$00000000,$00000000,$D6FEEC00,$C6D6D6D6,$00000000,
    $00000000,$6666DC00,$66666666,$00000000,$00000000,$C6C67C00,$7CC6C6C6,$00000000,
    $00000000,$6666DC00,$7C666666,$00F06060,$00000000,$CCCC7600,$7CCCCCCC,$001E0C0C,
    $00000000,$6676DC00,$F0606060,$00000000,$00000000,$60C67C00,$7CC60C38,$00000000,
    $30100000,$3030FC30,$1C363030,$00000000,$00000000,$CCCCCC00,$76CCCCCC,$00000000,
    $00000000,$66666600,$183C6666,$00000000,$00000000,$D6C6C600,$6CFED6D6,$00000000,
    $00000000,$386CC600,$C66C3838,$00000000,$00000000,$C6C6C600,$7EC6C6C6,$00F80C06,
    $00000000,$18CCFE00,$FEC66030,$00000000,$100C0000,$10601010,$0C101010,$00000000,
    $10100000,$10001010,$10101010,$00000000,$08300000,$08060808,$30080808,$00000000,
    $DC760000,$00000000,$00000000,$00000000,$023E0000,$12020202,$10307E32,$00000000,
    $00000000,$00000000,$00000000,$FF000000,$00000000,$00000000,$00000000,$FFFF0000,
    $00000000,$00000000,$00000000,$FFFFFF00,$00000000,$00000000,$00000000,$FFFFFFFF,
    $00000000,$00000000,$FF000000,$FFFFFFFF,$00000000,$00000000,$FFFF0000,$FFFFFFFF,
    $00000000,$00000000,$FFFFFF00,$FFFFFFFF,$00000000,$00000000,$FFFFFFFF,$FFFFFFFF,
    $00000000,$FF000000,$FFFFFFFF,$FFFFFFFF,$00000000,$FFFF0000,$FFFFFFFF,$FFFFFFFF,
    $00000000,$FFFFFF00,$FFFFFFFF,$FFFFFFFF,$00000000,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,
    $FF000000,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFF0000,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,
    $FFFFFF00,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$00FFFFFF,
    $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$0000FFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$000000FF,
    $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$00000000,$FFFFFFFF,$FFFFFFFF,$00FFFFFF,$00000000,
    $FFFFFFFF,$FFFFFFFF,$0000FFFF,$00000000,$FFFFFFFF,$FFFFFFFF,$000000FF,$00000000,
    $FFFFFFFF,$FFFFFFFF,$00000000,$00000000,$FFFFFFFF,$00FFFFFF,$00000000,$00000000,
    $FFFFFFFF,$0000FFFF,$00000000,$00000000,$FFFFFFFF,$000000FF,$00000000,$00000000,
    $FFFFFFFF,$00000000,$00000000,$00000000,$00FFFFFF,$00000000,$00000000,$00000000,
    $0000FFFF,$00000000,$00000000,$00000000,$000000FF,$00000000,$00000000,$00000000,
    $10101010,$10101010,$10101010,$7C101010,$00000000,$0A110000,$110A0404,$00000000,
    $AACC0000,$AACAAAAA,$CCAAAAAA,$00000000,$AA4C0000,$4A8A8AAA,$4CAA2A2A,$00000000,
    $44EE0000,$44444444,$44444444,$00000000,$4AE40000,$4848484A,$444A4848,$00000000,
    $AAAA0000,$AAEEAAAA,$AAAAAAAA,$00000000,$00000000,$FFFFFF00,$80808000,$00808080,
    $00000000,$FFFFFF00,$A0A0A000,$00A0A0A0,$00000000,$FFFFFF00,$A8A8A800,$00A8A8A8,
    $00000000,$FFFFFF00,$AAAAAA00,$00AAAAAA,$10101010,$FFFFFF10,$AAAAAA00,$00AAAAAA,
    $00000000,$60606000,$7E606060,$00000000,$00000000,$C6C6FC00,$C6C6CCFC,$00000000,
    $00100015,$1C0C0010,$0C7E6C3C,$001E0C0C,$96959566,$10006494,$10001000,$00001500,
    $90900000,$F7F09090,$97949291,$00000000,$00100010,$38000010,$00003838,$00000000,
    $44114411,$44114411,$44114411,$44114411,$AA55AA55,$AA55AA55,$AA55AA55,$AA55AA55,
    $77DD77DD,$77DD77DD,$77DD77DD,$77DD77DD,$10101010,$10101010,$10101010,$10101010,
    $10101010,$F0101010,$10101010,$10101010,$10101010,$F0F0F010,$10101010,$10101010,
    $3C3C3C3C,$FC3C3C3C,$3C3C3C3C,$3C3C3C3C,$00000000,$FC000000,$3C3C3C3C,$3C3C3C3C,
    $00000000,$F0F0F000,$10101010,$10101010,$3C3C3C3C,$FCFCFC3C,$3C3C3C3C,$3C3C3C3C,
    $3C3C3C3C,$3C3C3C3C,$3C3C3C3C,$3C3C3C3C,$00000000,$FCFCFC00,$3C3C3C3C,$3C3C3C3C,
    $3C3C3C3C,$FCFCFC3C,$00000000,$00000000,$3C3C3C3C,$FC3C3C3C,$00000000,$00000000,
    $10101010,$F0F0F010,$00000000,$00000000,$00000000,$F0000000,$10101010,$10101010,
    $10101010,$1F101010,$00000000,$00000000,$10101010,$FF101010,$00000000,$00000000,
    $00000000,$FF000000,$10101010,$10101010,$10101010,$1F101010,$10101010,$10101010,
    $00000000,$FF000000,$00000000,$00000000,$10101010,$FF101010,$10101010,$10101010,
    $10101010,$1F1F1F10,$10101010,$10101010,$3C3C3C3C,$3F3C3C3C,$3C3C3C3C,$3C3C3C3C,
    $3C3C3C3C,$3F3F3F3C,$00000000,$00000000,$00000000,$3F3F3F00,$3C3C3C3C,$3C3C3C3C,
    $3C3C3C3C,$FFFFFF3C,$00000000,$00000000,$00000000,$FFFFFF00,$3C3C3C3C,$3C3C3C3C,
    $3C3C3C3C,$3F3F3F3C,$3C3C3C3C,$3C3C3C3C,$00000000,$FFFFFF00,$00000000,$00000000,
    $3C3C3C3C,$FFFFFF3C,$3C3C3C3C,$3C3C3C3C,$10101010,$FFFFFF10,$00000000,$00000000,
    $3C3C3C3C,$FF3C3C3C,$00000000,$00000000,$00000000,$FFFFFF00,$10101010,$10101010,
    $00000000,$FF000000,$3C3C3C3C,$3C3C3C3C,$3C3C3C3C,$3F3C3C3C,$00000000,$00000000,
    $10101010,$1F1F1F10,$00000000,$00000000,$00000000,$1F1F1F00,$10101010,$10101010,
    $00000000,$3F000000,$3C3C3C3C,$3C3C3C3C,$3C3C3C3C,$FF3C3C3C,$3C3C3C3C,$3C3C3C3C,
    $10101010,$FFFFFF10,$10101010,$10101010,$10101010,$F0101010,$00000000,$00000000,
    $00000000,$1F000000,$10101010,$10101010,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,
    $00000000,$FF000000,$FFFFFFFF,$FFFFFFFF,$F0F0F0F0,$F0F0F0F0,$F0F0F0F0,$F0F0F0F0,
    $0F0F0F0F,$0F0F0F0F,$0F0F0F0F,$0F0F0F0F,$FFFFFFFF,$00FFFFFF,$00000000,$00000000,
    $00100010,$00920010,$00100010,$00920010,$00100010,$00920010,$00100010,$FF100010,
    $00100010,$00920010,$00100010,$FFFF0010,$00100010,$00920010,$00100010,$FFFFFF10,
    $00100010,$00920010,$00100010,$FFFFFFFF,$00100010,$00920010,$FF100010,$FFFFFFFF,
    $00100010,$00920010,$FFFF0010,$FFFFFFFF,$00100010,$00920010,$FFFFFF10,$FFFFFFFF,
    $00100010,$00920010,$FFFFFFFF,$FFFFFFFF,$00100010,$FF920010,$FFFFFFFF,$FFFFFFFF,
    $00100010,$FFFF0010,$FFFFFFFF,$FFFFFFFF,$00100010,$FFFFFF10,$FFFFFFFF,$FFFFFFFF,
    $00100010,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FF100010,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,
    $FFFF0010,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFF10,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,
    $01010101,$01010101,$01010101,$01010101,$10000000,$10101010,$10101010,$00000000,
    $00000000,$FF000000,$00100010,$00920010,$00100010,$FF100010,$00000000,$00000000,
    $18783818,$10081C1A,$00000020,$00000000,$186C6C38,$10087C32,$00000020,$00000000,
    $00100010,$00100010,$00100010,$00100010,$00010001,$00010001,$00010001,$00010001,
    $00100015,$00100010,$00100010,$00100010,$00000000,$28281000,$00001028,$00000000,
    $00000000,$10000000,$00000000,$00000000,$03010000,$CC040602,$307058C8,$00000000,
    $3E1C0800,$FFFFFF7F,$00000000,$00000000,$00000000,$FFFFFF00,$081C3E7F,$00000000,
    $00000000,$7C7C7C7C,$007C7C7C,$00000000,$00000000,$00000000,$00000000,$00000000);export name 'TC__ADT2DATA____FONT8X16';

const
  vga_font8x16: array[0..1023] of Dword = (
    $00000000,$00000000,$00000000,$00000000,$817E0000,$BD8181A5,$7E818199,$00000000,
    $FF7E0000,$C3FFFFDB,$7EFFFFE7,$00000000,$00000000,$FEFEFE6C,$10387CFE,$00000000,
    $00000000,$FE7C3810,$0010387C,$00000000,$18000000,$E7E73C3C,$3C1818E7,$00000000,
    $18000000,$FFFF7E3C,$3C18187E,$00000000,$00000000,$3C180000,$0000183C,$00000000,
    $FFFFFFFF,$C3E7FFFF,$FFFFE7C3,$FFFFFFFF,$00000000,$42663C00,$003C6642,$00000000,
    $FFFFFFFF,$BD99C3FF,$FFC399BD,$FFFFFFFF,$0E1E0000,$CC78321A,$78CCCCCC,$00000000,
    $663C0000,$3C666666,$18187E18,$00000000,$333F0000,$3030303F,$E0F07030,$00000000,
    $637F0000,$6363637F,$E6E76763,$000000C0,$18000000,$E73CDB18,$1818DB3C,$00000000,
    $E0C08000,$F8FEF8F0,$80C0E0F0,$00000000,$0E060200,$3EFE3E1E,$02060E1E,$00000000,
    $3C180000,$1818187E,$00183C7E,$00000000,$66660000,$66666666,$66660066,$00000000,
    $DB7F0000,$1B7BDBDB,$1B1B1B1B,$00000000,$60C67C00,$C6C66C38,$C60C386C,$0000007C,
    $00000000,$00000000,$FEFEFEFE,$00000000,$3C180000,$1818187E,$7E183C7E,$00000000,
    $3C180000,$1818187E,$18181818,$00000000,$18180000,$18181818,$183C7E18,$00000000,
    $00000000,$FE0C1800,$0000180C,$00000000,$00000000,$FE603000,$00003060,$00000000,
    $00000000,$C0C00000,$0000FEC0,$00000000,$00000000,$FF662400,$00002466,$00000000,
    $00000000,$7C383810,$00FEFE7C,$00000000,$00000000,$7C7CFEFE,$00103838,$00000000,
    $00000000,$00000000,$00000000,$00000000,$3C180000,$18183C3C,$18180018,$00000000,
    $66666600,$00000024,$00000000,$00000000,$6C000000,$6C6CFE6C,$6C6CFE6C,$00000000,
    $C67C1818,$067CC0C2,$7CC68606,$00001818,$00000000,$180CC6C2,$86C66030,$00000000,
    $6C380000,$DC76386C,$76CCCCCC,$00000000,$30303000,$00000060,$00000000,$00000000,
    $180C0000,$30303030,$0C183030,$00000000,$18300000,$0C0C0C0C,$30180C0C,$00000000,
    $00000000,$FF3C6600,$0000663C,$00000000,$00000000,$7E181800,$00001818,$00000000,
    $00000000,$00000000,$18181800,$00000030,$00000000,$FE000000,$00000000,$00000000,
    $00000000,$00000000,$18180000,$00000000,$00000000,$180C0602,$80C06030,$00000000,
    $663C0000,$DBDBC3C3,$3C66C3C3,$00000000,$38180000,$18181878,$7E181818,$00000000,
    $C67C0000,$30180C06,$FEC6C060,$00000000,$C67C0000,$063C0606,$7CC60606,$00000000,
    $1C0C0000,$FECC6C3C,$1E0C0C0C,$00000000,$C0FE0000,$06FCC0C0,$7CC60606,$00000000,
    $60380000,$C6FCC0C0,$7CC6C6C6,$00000000,$C6FE0000,$180C0606,$30303030,$00000000,
    $C67C0000,$C67CC6C6,$7CC6C6C6,$00000000,$C67C0000,$067EC6C6,$780C0606,$00000000,
    $00000000,$00001818,$00181800,$00000000,$00000000,$00001818,$30181800,$00000000,
    $06000000,$6030180C,$060C1830,$00000000,$00000000,$00007E00,$0000007E,$00000000,
    $60000000,$060C1830,$6030180C,$00000000,$C67C0000,$18180CC6,$18180018,$00000000,
    $7C000000,$DEDEC6C6,$7CC0DCDE,$00000000,$38100000,$FEC6C66C,$C6C6C6C6,$00000000,
    $66FC0000,$667C6666,$FC666666,$00000000,$663C0000,$C0C0C0C2,$3C66C2C0,$00000000,
    $6CF80000,$66666666,$F86C6666,$00000000,$66FE0000,$68786862,$FE666260,$00000000,
    $66FE0000,$68786862,$F0606060,$00000000,$663C0000,$DEC0C0C2,$3A66C6C6,$00000000,
    $C6C60000,$C6FEC6C6,$C6C6C6C6,$00000000,$183C0000,$18181818,$3C181818,$00000000,
    $0C1E0000,$0C0C0C0C,$78CCCCCC,$00000000,$66E60000,$78786C66,$E666666C,$00000000,
    $60F00000,$60606060,$FE666260,$00000000,$E7C30000,$C3DBFFFF,$C3C3C3C3,$00000000,
    $E6C60000,$CEDEFEF6,$C6C6C6C6,$00000000,$C67C0000,$C6C6C6C6,$7CC6C6C6,$00000000,
    $66FC0000,$607C6666,$F0606060,$00000000,$C67C0000,$C6C6C6C6,$7CDED6C6,$00000E0C,
    $66FC0000,$6C7C6666,$E6666666,$00000000,$C67C0000,$0C3860C6,$7CC6C606,$00000000,
    $DBFF0000,$18181899,$3C181818,$00000000,$C6C60000,$C6C6C6C6,$7CC6C6C6,$00000000,
    $C3C30000,$C3C3C3C3,$183C66C3,$00000000,$C3C30000,$DBC3C3C3,$6666FFDB,$00000000,
    $C3C30000,$18183C66,$C3C3663C,$00000000,$C3C30000,$183C66C3,$3C181818,$00000000,
    $C3FF0000,$30180C86,$FFC3C160,$00000000,$303C0000,$30303030,$3C303030,$00000000,
    $80000000,$3870E0C0,$02060E1C,$00000000,$0C3C0000,$0C0C0C0C,$3C0C0C0C,$00000000,
    $C66C3810,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$0000FF00,
    $00183030,$00000000,$00000000,$00000000,$00000000,$7C0C7800,$76CCCCCC,$00000000,
    $60E00000,$666C7860,$7C666666,$00000000,$00000000,$C0C67C00,$7CC6C0C0,$00000000,
    $0C1C0000,$CC6C3C0C,$76CCCCCC,$00000000,$00000000,$FEC67C00,$7CC6C0C0,$00000000,
    $6C380000,$60F06064,$F0606060,$00000000,$00000000,$CCCC7600,$7CCCCCCC,$0078CC0C,
    $60E00000,$66766C60,$E6666666,$00000000,$18180000,$18183800,$3C181818,$00000000,
    $06060000,$06060E00,$06060606,$003C6666,$60E00000,$786C6660,$E6666C78,$00000000,
    $18380000,$18181818,$3C181818,$00000000,$00000000,$DBFFE600,$DBDBDBDB,$00000000,
    $00000000,$6666DC00,$66666666,$00000000,$00000000,$C6C67C00,$7CC6C6C6,$00000000,
    $00000000,$6666DC00,$7C666666,$00F06060,$00000000,$CCCC7600,$7CCCCCCC,$001E0C0C,
    $00000000,$6676DC00,$F0606060,$00000000,$00000000,$60C67C00,$7CC60C38,$00000000,
    $30100000,$3030FC30,$1C363030,$00000000,$00000000,$CCCCCC00,$76CCCCCC,$00000000,
    $00000000,$C3C3C300,$183C66C3,$00000000,$00000000,$C3C3C300,$66FFDBDB,$00000000,
    $00000000,$3C66C300,$C3663C18,$00000000,$00000000,$C6C6C600,$7EC6C6C6,$00F80C06,
    $00000000,$18CCFE00,$FEC66030,$00000000,$180E0000,$18701818,$0E181818,$00000000,
    $18180000,$18001818,$18181818,$00000000,$18700000,$180E1818,$70181818,$00000000,
    $DC760000,$00000000,$00000000,$00000000,$00000000,$C66C3810,$00FEC6C6,$00000000,
    $663C0000,$C0C0C0C2,$0C3C66C2,$00007C06,$00CC0000,$CCCCCC00,$76CCCCCC,$00000000,
    $30180C00,$FEC67C00,$7CC6C0C0,$00000000,$6C381000,$7C0C7800,$76CCCCCC,$00000000,
    $00CC0000,$7C0C7800,$76CCCCCC,$00000000,$18306000,$7C0C7800,$76CCCCCC,$00000000,
    $386C3800,$7C0C7800,$76CCCCCC,$00000000,$00000000,$6060663C,$060C3C66,$0000003C,
    $6C381000,$FEC67C00,$7CC6C0C0,$00000000,$00C60000,$FEC67C00,$7CC6C0C0,$00000000,
    $18306000,$FEC67C00,$7CC6C0C0,$00000000,$00660000,$18183800,$3C181818,$00000000,
    $663C1800,$18183800,$3C181818,$00000000,$18306000,$18183800,$3C181818,$00000000,
    $1000C600,$C6C66C38,$C6C6C6FE,$00000000,$00386C38,$C6C66C38,$C6C6C6FE,$00000000,
    $00603018,$7C6066FE,$FE666060,$00000000,$00000000,$1B3B6E00,$77DCD87E,$00000000,
    $6C3E0000,$CCFECCCC,$CECCCCCC,$00000000,$6C381000,$C6C67C00,$7CC6C6C6,$00000000,
    $00C60000,$C6C67C00,$7CC6C6C6,$00000000,$18306000,$C6C67C00,$7CC6C6C6,$00000000,
    $CC783000,$CCCCCC00,$76CCCCCC,$00000000,$18306000,$CCCCCC00,$76CCCCCC,$00000000,
    $00C60000,$C6C6C600,$7EC6C6C6,$00780C06,$7C00C600,$C6C6C6C6,$7CC6C6C6,$00000000,
    $C600C600,$C6C6C6C6,$7CC6C6C6,$00000000,$7E181800,$C0C0C0C3,$18187EC3,$00000000,
    $646C3800,$6060F060,$FCE66060,$00000000,$66C30000,$18FF183C,$181818FF,$00000000,
    $6666FC00,$6F66627C,$F3666666,$00000000,$181B0E00,$187E1818,$18181818,$000070D8,
    $60301800,$7C0C7800,$76CCCCCC,$00000000,$30180C00,$18183800,$3C181818,$00000000,
    $60301800,$C6C67C00,$7CC6C6C6,$00000000,$60301800,$CCCCCC00,$76CCCCCC,$00000000,
    $DC760000,$6666DC00,$66666666,$00000000,$C600DC76,$DEFEF6E6,$C6C6C6CE,$00000000,
    $6C6C3C00,$007E003E,$00000000,$00000000,$6C6C3800,$007C0038,$00000000,$00000000,
    $30300000,$60303000,$7CC6C6C0,$00000000,$00000000,$C0FE0000,$00C0C0C0,$00000000,
    $00000000,$06FE0000,$00060606,$00000000,$C2C0C000,$3018CCC6,$069BCE60,$00001F0C,
    $C2C0C000,$3018CCC6,$3E96CE66,$00000606,$18180000,$18181800,$183C3C3C,$00000000,
    $00000000,$D86C3600,$0000366C,$00000000,$00000000,$366CD800,$0000D86C,$00000000,
    $44114411,$44114411,$44114411,$44114411,$AA55AA55,$AA55AA55,$AA55AA55,$AA55AA55,
    $77DD77DD,$77DD77DD,$77DD77DD,$77DD77DD,$18181818,$18181818,$18181818,$18181818,
    $18181818,$F8181818,$18181818,$18181818,$18181818,$F818F818,$18181818,$18181818,
    $36363636,$F6363636,$36363636,$36363636,$00000000,$FE000000,$36363636,$36363636,
    $00000000,$F818F800,$18181818,$18181818,$36363636,$F606F636,$36363636,$36363636,
    $36363636,$36363636,$36363636,$36363636,$00000000,$F606FE00,$36363636,$36363636,
    $36363636,$FE06F636,$00000000,$00000000,$36363636,$FE363636,$00000000,$00000000,
    $18181818,$F818F818,$00000000,$00000000,$00000000,$F8000000,$18181818,$18181818,
    $18181818,$1F181818,$00000000,$00000000,$18181818,$FF181818,$00000000,$00000000,
    $00000000,$FF000000,$18181818,$18181818,$18181818,$1F181818,$18181818,$18181818,
    $00000000,$FF000000,$00000000,$00000000,$18181818,$FF181818,$18181818,$18181818,
    $18181818,$1F181F18,$18181818,$18181818,$36363636,$37363636,$36363636,$36363636,
    $36363636,$3F303736,$00000000,$00000000,$00000000,$37303F00,$36363636,$36363636,
    $36363636,$FF00F736,$00000000,$00000000,$00000000,$F700FF00,$36363636,$36363636,
    $36363636,$37303736,$36363636,$36363636,$00000000,$FF00FF00,$00000000,$00000000,
    $36363636,$F700F736,$36363636,$36363636,$18181818,$FF00FF18,$00000000,$00000000,
    $36363636,$FF363636,$00000000,$00000000,$00000000,$FF00FF00,$18181818,$18181818,
    $00000000,$FF000000,$36363636,$36363636,$36363636,$3F363636,$00000000,$00000000,
    $18181818,$1F181F18,$00000000,$00000000,$00000000,$1F181F00,$18181818,$18181818,
    $00000000,$3F000000,$36363636,$36363636,$36363636,$FF363636,$36363636,$36363636,
    $18181818,$FF18FF18,$18181818,$18181818,$18181818,$F8181818,$00000000,$00000000,
    $00000000,$1F000000,$18181818,$18181818,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,
    $00000000,$FF000000,$FFFFFFFF,$FFFFFFFF,$F0F0F0F0,$F0F0F0F0,$F0F0F0F0,$F0F0F0F0,
    $0F0F0F0F,$0F0F0F0F,$0F0F0F0F,$0F0F0F0F,$FFFFFFFF,$00FFFFFF,$00000000,$00000000,
    $00000000,$D8DC7600,$76DCD8D8,$00000000,$CC780000,$CCD8CCCC,$CCC6C6C6,$00000000,
    $C6FE0000,$C0C0C0C6,$C0C0C0C0,$00000000,$00000000,$6C6C6CFE,$6C6C6C6C,$00000000,
    $FE000000,$183060C6,$FEC66030,$00000000,$00000000,$D8D87E00,$70D8D8D8,$00000000,
    $00000000,$66666666,$60607C66,$000000C0,$00000000,$1818DC76,$18181818,$00000000,
    $7E000000,$66663C18,$7E183C66,$00000000,$38000000,$FEC6C66C,$386CC6C6,$00000000,
    $6C380000,$6CC6C6C6,$EE6C6C6C,$00000000,$301E0000,$663E0C18,$3C666666,$00000000,
    $00000000,$DBDB7E00,$00007EDB,$00000000,$03000000,$DBDB7E06,$C0607EF3,$00000000,
    $301C0000,$607C6060,$1C306060,$00000000,$7C000000,$C6C6C6C6,$C6C6C6C6,$00000000,
    $00000000,$FE0000FE,$00FE0000,$00000000,$00000000,$187E1818,$FF000018,$00000000,
    $30000000,$0C060C18,$7E003018,$00000000,$0C000000,$30603018,$7E000C18,$00000000,
    $1B0E0000,$1818181B,$18181818,$18181818,$18181818,$18181818,$70D8D8D8,$00000000,
    $00000000,$7E001818,$00181800,$00000000,$00000000,$00DC7600,$0000DC76,$00000000,
    $6C6C3800,$00000038,$00000000,$00000000,$00000000,$18000000,$00000018,$00000000,
    $00000000,$00000000,$00000018,$00000000,$0C0C0F00,$EC0C0C0C,$1C3C6C6C,$00000000,
    $6C6CD800,$006C6C6C,$00000000,$00000000,$30D87000,$00F8C860,$00000000,$00000000,
    $00000000,$7C7C7C7C,$007C7C7C,$00000000,$00000000,$00000000,$00000000,$00000000);

{$IFNDEF GO32V2}

const
  adt2_icon_bitmap: array[0..782] of Dword = (
    $0C364D42,$00000000,$00360000,$00280000,$00200000,$00200000,$00010000,$00000018,
    $0C000000,$00000000,$00000000,$00000000,$00000000,$CAFF0000,$77CAFF77,$FF7ACDFF,
    $CDFF7ACD,$7ACDFF7A,$FF77CAFF,$CDFF77CA,$7ACDFF7A,$FF77CAFF,$CDFF77CA,$7ACDFF7A,
    $FF77CAFF,$CDFF77CA,$7ACDFF7A,$FF7ACDFF,$CDFF7ACD,$7ACDFF7A,$FF7ACCFF,$CDFF7ACC,
    $7ACDFF7A,$EA81CFFA,$C4F681C7,$79CCFF77,$FF7ACDFF,$C9FF7ACD,$76C9FF77,$FF76C9FF,
    $C9FF76C9,$77C9FF77,$FF77CAFF,$CAFF77CA,$77CAFF77,$FF77CAFF,$CAFF77CA,$77CAFF77,
    $FF77CAFF,$CAFF77CA,$77CAFF77,$FF77CAFF,$C9FF77CA,$77C9FF77,$FF77CAFF,$C9FF77CA,
    $76C9FF77,$19D4E397,$5366A487,$76C9FF53,$FF77C9FF,$C4FF76C5,$76C5FF74,$FF76C5FF,
    $C5FF76C5,$76C5FF76,$FF76C5FF,$C5FF76C5,$76C5FF76,$FF76C5FF,$C5FF76C5,$76C5FF76,
    $FF76C5FF,$C5FF76C5,$76C5FF76,$FF76C5FF,$C5FF76C5,$76C5FF76,$FF76C5FF,$C4FF76C5,
    $74C4FF74,$1AEFF47E,$45578571,$74C4FF48,$FF74C4FF,$BFFF74C1,$73C1FF73,$FF73BFFF,
    $BFFF73BF,$73BFFF73,$FF74C1FF,$C1FF74C1,$74C1FF74,$FF73C1FF,$C1FF73C1,$74C1FF74,
    $FF73BFFF,$C1FF73BF,$73C1FF73,$FF74C1FF,$C1FF74C1,$74C1FF74,$FF73C1FF,$C1FF73C1,
    $73BFFF74,$1AECF27D,$40528773,$73BFFF44,$FF73C1FF,$BBFF73BF,$71BBFF6E,$FF71BBFF,
    $BBFF71BB,$71BBFF71,$FF71BBFF,$BBFF71BB,$6EBBFF6E,$FF71BBFF,$BCFF71BB,$71BCFF71,
    $FF71BCFF,$BCFF71BC,$71BCFF71,$FF71BCFF,$BBFF71BC,$71BBFF71,$FF71BCFF,$BBFF71BC,
    $6EBBFF71,$16ECF07B,$4052836E,$6EBBFF45,$FF71BBFF,$B1FF6EB9,$6BB1FF6B,$FF6CB5FF,
    $B5FF6CB5,$6CB5FF6C,$FF6CB5FF,$B6FF6CB5,$6CB6FF6C,$FF6CB6FF,$B6FF6CB6,$6CB6FF6C,
    $FF6CB5FF,$B5FF6CB5,$6CB5FF6C,$FF6EB6FF,$B6FF6EB6,$6CB6FF6C,$FF6CB5FF,$B5FF6CB5,
    $6BB5FF6B,$16EAEF79,$4452836E,$6BB1FF47,$FF6BB1FF,$ADFF6BB1,$68ABFF68,$FF68ADFF,
    $ABFF68AD,$68ABFF68,$FF68ADFF,$ADFF68AD,$69ADFF69,$FF69ADFF,$ADFF69AD,$69ADFF69,
    $FF69ADFF,$ADFF69AD,$69ADFF69,$FF69B0FF,$ADFF69B0,$68ADFF68,$FF69B0FF,$ADFF69B0,
    $68ADFF68,$26F0F380,$45539080,$68ABFF4B,$FF68ADFF,$A5FF68AB,$63A5FF63,$FF63A5FF,
    $A5FF63A5,$63A5FF63,$FF63A7FF,$A5FF63A7,$63A5FF63,$FF63A5FF,$A5FF63A5,$63A5FF63,
    $FF63A5FF,$A5FF63A5,$63A5FF63,$FF66A7FF,$A5FF66A7,$63A5FF63,$FF63A5FF,$A5FF63A5,
    $62A2FF63,$28F0F381,$404D9382,$63A5FF47,$FF63A5FF,$99FF62A2,$5F9CFF5F,$FF5F9CFF,
    $9CFF5F9C,$5F9CFF5F,$FF5F99FF,$9EFF5F9C,$609EFF60,$FF5F9CFF,$9CFF5F9C,$5F9CFF5F,
    $FF5F9CFF,$9CFF5F9C,$5F9CFF5F,$FF609EFF,$9EFF609E,$609EFF60,$FF609CFF,$9CFF609C,
    $5F9CFF60,$28F1F480,$3B489382,$5F9CFF44,$FF5F99FF,$8EF45D99,$5891F457,$AB588EF4,
    $3D328299,$3B191058,$F55891F4,$91F55891,$5891F558,$F55891F5,$91F55891,$5891F558,
    $F55891F5,$91F55891,$5891F558,$F75893F7,$91F55893,$5891F558,$F55891F5,$91F55891,
    $578EF458,$2AF0F27F,$404A9585,$578EF447,$F4578EF4,$82E3578E,$5283E64F,$A44F83E6,
    $7619D2E3,$2D00009A,$E6350F05,$83E65283,$5283E74F,$E65283E6,$85E75283,$5485E754,
    $E65283E6,$83E75283,$5283E752,$E65283E6,$85E75283,$5485E754,$E65283E6,$85E75283,
    $5283E652,$33F0F27F,$47529D8F,$4F82E650,$E34F82E3,$74D24F82,$4B76D549,$9E4971D2,
    $FF96D2E0,$9F7D1EFF,$012F0000,$74D3350F,$4974D349,$D54B76D5,$76D54B76,$4B76D54B,
    $D54B76D5,$76D54B76,$4B76D54B,$D34B74D3,$74D34B74,$4B74D34B,$D54B76D5,$76D54B76,
    $4B76D54B,$3AF2F37F,$444CA294,$4974D34D,$D34B74D3,$65BF4B74,$4166C141,$B64165BF,
    $FF907693,$FFFF85FF,$00967113,$07002D00,$4165C130,$C14165BF,$65C14166,$4165C141,
    $C14165C1,$65C14165,$4165C141,$C14166C1,$65C14166,$4165C141,$C14166C1,$65BF4166,
    $4062BF40,$2FF1F27E,$29339988,$4062BF3A,$BE4165BF,$51AA4062,$3752AB37,$A73751AA,
    $82A23551,$FDFF7D6B,$07FFFF71,$00008B65,$27000023,$AA3752AA,$52AA3751,$3752AA37,
    $AA3752AA,$52AA3752,$3752AA37,$AA3752AA,$51AA3752,$3751AA37,$AA3751AA,$52AB3751,
    $3752AB38,$23EDED79,$1B238F7C,$3751AA32,$A73751AA,$3D90354E,$2C3D912A,$902C3D90,
    $3D902C3D,$2C3D902C,$65F8F876,$5A00FFFF,$1C000082,$90210000,$3A902A3A,$2C3D902A,
    $912C3D91,$3D902C3D,$2A3D902A,$902C3D90,$3D912C3D,$2C3D912C,$902A3D90,$3D912A3D,
    $2C3D902C,$2DEEED78,$262B9988,$2A3A903B,$8E2C3D90,$23712A3A,$1E26741C,$741E2674,
    $24741E26,$1C24711E,$761C2471,$FF62FDFB,$7C5100FF,$00180000,$24711C00,$1C24711C,
    $711C2471,$24741C24,$1C24741C,$741C2371,$24741C24,$1C24741C,$741C2474,$24711C24,
    $1C24711C,$40F1F07A,$2F30A89D,$1C247445,$711C2474,$13601C24,$12136210,$60101360,
    $13621013,$12136212,$60101360,$F8741013,$FFFF69FA,$007D5200,$00001300,$10136019,
    $62101360,$13621215,$12136212,$24101360,$06041901,$33120B26,$1A402711,$3517503B,
    $31200E49,$2CD5CA63,$0B109887,$10136029,$62121562,$05571213,$04055704,$57040557,
    $05570405,$04055704,$55040557,$05550402,$FFFF7C04,$00FFFF6F,$00008057,$16000012,
    $55040255,$05570402,$04055704,$34040557,$F5676E5D,$FAF46DF9,$72F9F36D,$F875F9F5,
    $FCFA73FB,$3BFCFA7C,$0209AA9F,$04025521,$57040557,$004E0405,$00004E00,$4E00004E,
    $004E0000,$00004E00,$4E00004E,$004E0000,$00004F00,$71FFFF7C,$5100FFFF,$1000007C,
    $4E100000,$004E0000,$00004F00,$4E00004E,$6B542F2D,$6C6B546C,$51716F57,$69506B69,
    $7877586C,$49F8F778,$0B10B4AD,$00004E28,$4E00004F,$00470000,$00004600,$47000047,
    $00470000,$00004700,$46000046,$00470000,$00004600,$7C000046,$FF7CFFFF,$B3961BFF,
    $00120000,$00461600,$00004700,$47000047,$00470000,$00004700,$47000047,$00470000,
    $00004600,$3BE1DF71,$060FA89C,$00004623,$47000047,$00400000,$00004000,$40000040,
    $00410000,$00004100,$41000041,$00410000,$00004100,$40000040,$FF820000,$FFFF96FF,
    $00CFB63A,$00001600,$00003D12,$40000040,$00410000,$00004100,$41000041,$00400000,
    $00004000,$33DFDD6E,$0004A093,$00004017,$40000041,$003A0000,$00003A00,$3B00003B,
    $003B0000,$00003B00,$3A00003A,$003A0000,$00003A00,$3A00003B,$003A0000,$D0D88800,
    $47FFFFB6,$0000DBC5,$07000012,$3A00003A,$003A0000,$00003A00,$3A00003A,$003A0000,
    $00003A00,$32E3E170,$00009F92,$00003B0F,$3B00003B,$00350000,$00003500,$35000035,
    $00350000,$00003500,$35000035,$00350000,$00003500,$35000035,$00340000,$00003400,
    $B6CCD383,$AD32FFFF,$0D0000C7,$34050000,$00350000,$00003500,$35000035,$00350000,
    $00003500,$33E6E573,$0000A293,$0000350C,$35000035,$00320000,$00003200,$32000032,
    $00320000,$00003200,$32000032,$00320000,$00003200,$2F00002F,$00320000,$00002F00,
    $7700002F,$FF9FC1C5,$CCB135FF,$0C120000,$002F0000,$00002F00,$32000032,$00320000,
    $00002F00,$3FE7E675,$0000ADA0,$00002F10,$2F000032,$002C0000,$00002D00,$2D00002D,
    $002D0000,$00002D00,$2C00002C,$002D0000,$00002D00,$2C00002C,$002C0000,$00002C00,
    $2C00002D,$C4770000,$FFFFABBE,$15D2BB38,$002D0200,$00002D00,$2D00002D,$002C0000,
    $00002C00,$46E7E675,$0006B2A7,$00002D19,$2D00002D,$00290000,$00002900,$29000029,
    $002C0000,$00002C00,$2C00002C,$00290000,$00002900,$29000029,$00290000,$00002900,
    $29000029,$00290000,$09073200,$3A525140,$00291010,$00002900,$2C00002C,$00290000,
    $00002900,$46E6E574,$010BB2A7,$0000291B,$29000029,$00260000,$00002700,$27000027,
    $00270000,$00002700,$27000027,$00260000,$00002600,$26000026,$00270000,$00002700,
    $27000027,$00270000,$00002700,$26000026,$00260000,$00002600,$27000027,$00260000,
    $00002600,$47E5E373,$0009B1A8,$00002619,$26000027,$00240000,$00002600,$26000026,
    $00240000,$00002400,$26000026,$00240000,$00002400,$26000026,$00240000,$00002400,
    $26000026,$00240000,$00002400,$26000026,$00240000,$00002400,$26000026,$00240000,
    $00002400,$4FEBEB7D,$0004BAB2,$00002414,$24000026,$00210000,$00002100,$24000024,
    $00210000,$00002100,$24000024,$00210000,$00002100,$24000024,$00240000,$00002400,
    $24000024,$00210000,$00002100,$21000021,$00240000,$00002400,$24000024,$00240000,
    $00002100,$3CD5D564,$0001A79D,$00002110,$24000024,$00210000,$00002100,$21000021,
    $00200000,$00002000,$20000020,$00210000,$00002100,$21000021,$00210000,$00002100,
    $21000021,$00200000,$00002000,$20000020,$00200000,$00002000,$21000021,$00210000,
    $00002000,$39E0E068,$0000A599,$0000200F,$20000021,$00200000,$00002000,$1E00001E,
    $00200000,$00002000,$1E00001E,$001E0000,$00001E00,$1E00001E,$00200000,$00002000,
    $20000020,$00200000,$00002000,$1E00001E,$00200000,$00002000,$20000020,$00200000,
    $00001E00,$38D9D967,$0000AB9C,$0000200C,$20000020,$001B0000,$00001E00,$1E00001E,
    $001E0000,$00001E00,$1E00001E,$001E0000,$00001E00,$1E00001E,$001E0000,$00001E00,
    $1E00001E,$001E0000,$00001E00,$1E00001E,$001E0000,$00001E00,$1E00001E,$001B0000,
    $00001B00,$2BD6D667,$0000867A,$00001E09,$1E00001E,$00000000,$00000000);

{$ENDIF}

implementation

end.
