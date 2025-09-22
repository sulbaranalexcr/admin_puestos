require 'json'
require_relative 'config/environment'

monedas = [
  {
    "pais" => "REPUBLICA BOLIVARIANA DE VENEZUELA",
    "divisa" => "Bolivar",
    "codigo" => "VEF",
    "numero" => 937
  },
  {
    "pais" => "ESTADOS UNIDOS DE AMERICA",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "AFGANISTAN",
    "divisa" => "Afgani afgano",
    "codigo" => "AFN",
    "numero" => 971
  },
  {
    "pais" => "ALBANIA",
    "divisa" => "Lek",
    "codigo" => "ALL",
    "numero" => 8
  },
  {
    "pais" => "ALEMANIA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "ALGERIA",
    "divisa" => "Dinar argelino",
    "codigo" => "DZD",
    "numero" => 12
  },
  {
    "pais" => "ANDORRA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "ANGOLA",
    "divisa" => "Kwanza angoleno",
    "codigo" => "AOA",
    "numero" => 973
  },
  {
    "pais" => "ANGUILLA",
    "divisa" => "Dolar del Caribe Oriental",
    "codigo" => "XCD",
    "numero" => 951
  },
  {
    "pais" => "ANTIGUA Y BARBUDA",
    "divisa" => "Dolar del Caribe Oriental",
    "codigo" => "XCD",
    "numero" => 951
  },
  {
    "pais" => "ANTARTICA",
    "divisa" => "Sin divisa universal",
    "codigo" => "",
    "numero" => ""
  },
  {
    "pais" => "ARABIA SAUDITA",
    "divisa" => "Riyal saudi",
    "codigo" => "SAR",
    "numero" => 682
  },
  {
    "pais" => "ARGENTINA",
    "divisa" => "Peso argentino",
    "codigo" => "ARS",
    "numero" => 32
  },
  {
    "pais" => "ARMENIA",
    "divisa" => "Dram armenio",
    "codigo" => "AMD",
    "numero" => 51
  },
  {
    "pais" => "ARUBA",
    "divisa" => "Florin arubeno",
    "codigo" => "AWG",
    "numero" => 533
  },
  {
    "pais" => "AUSTRALIA",
    "divisa" => "Dolar australiano",
    "codigo" => "AUD",
    "numero" => 36
  },
  {
    "pais" => "AUSTRIA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "AZERBAIYAN",
    "divisa" => "Manat azerbaiyano",
    "codigo" => "AZN",
    "numero" => 944
  },
  {
    "pais" => "BAHAMAS (LAS)",
    "divisa" => "Dolar bahameno",
    "codigo" => "BSD",
    "numero" => 44
  },
  {
    "pais" => "BANGLADESH",
    "divisa" => "Taka",
    "codigo" => "BDT",
    "numero" => 50
  },
  {
    "pais" => "BARBADOS",
    "divisa" => "Dolar de Barbados",
    "codigo" => "BBD",
    "numero" => 52
  },
  {
    "pais" => "BAREIN",
    "divisa" => "Dinar bareini",
    "codigo" => "BHD",
    "numero" => 48
  },
  {
    "pais" => "BELICE",
    "divisa" => "Dolar beliceno",
    "codigo" => "BZD",
    "numero" => 84
  },
  {
    "pais" => "BENIN",
    "divisa" => "Franco CFA de Africa Occidental",
    "codigo" => "XOF",
    "numero" => 952
  },
  {
    "pais" => "BERMUDA",
    "divisa" => "Dolar bermudeno",
    "codigo" => "BMD",
    "numero" => 60
  },
  {
    "pais" => "BIELORRUSIA",
    "divisa" => "Rublo bielorruso",
    "codigo" => "BYR",
    "numero" => 974
  },
  {
    "pais" => "BIRMANIA",
    "divisa" => "Kyat birmano",
    "codigo" => "MMK",
    "numero" => 104
  },
  {
    "pais" => "BOLIVIA (ESTADO PLURINACIONAL DE)",
    "divisa" => "Boliviano",
    "codigo" => "BOB",
    "numero" => 68
  },
  {
    "pais" => "BOLIVIA (ESTADO PLURINACIONAL DE)",
    "divisa" => "Mvdol",
    "codigo" => "BOV",
    "numero" => 984
  },
  {
    "pais" => "BONAIRE, SAN EUSTAQUIO Y SABA",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "BOSNIA Y HERZEGOVINA",
    "divisa" => "Marco bosnioherzegovino",
    "codigo" => "BAM",
    "numero" => 977
  },
  {
    "pais" => "BOTSUANA",
    "divisa" => "Pula",
    "codigo" => "BWP",
    "numero" => 72
  },
  {
    "pais" => "BRASIL",
    "divisa" => "Real brasileno",
    "codigo" => "BRL",
    "numero" => 986
  },
  {
    "pais" => "BRUNEI DARUSSALAM",
    "divisa" => "Dolar de Brunei",
    "codigo" => "BND",
    "numero" => 96
  },
  {
    "pais" => "BULGARIA",
    "divisa" => "Lev",
    "codigo" => "BGN",
    "numero" => 975
  },
  {
    "pais" => "BURKINA FASO",
    "divisa" => "Franco CFA de Africa Occidental",
    "codigo" => "XOF",
    "numero" => 952
  },
  {
    "pais" => "BURUNDI",
    "divisa" => "Franco burundes",
    "codigo" => "BIF",
    "numero" => 108
  },
  {
    "pais" => "BUTAN",
    "divisa" => "Ngultrum butanes",
    "codigo" => "BTN",
    "numero" => 64
  },
  {
    "pais" => "BUTAN",
    "divisa" => "Rupia india",
    "codigo" => "INR",
    "numero" => 356
  },
  {
    "pais" => "BELGICA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "CABO VERDE",
    "divisa" => "Escudo caboverdiano",
    "codigo" => "CVE",
    "numero" => 132
  },
  {
    "pais" => "CAMBOYA",
    "divisa" => "Riel camboyano",
    "codigo" => "KHR",
    "numero" => 116
  },
  {
    "pais" => "CAMERUN",
    "divisa" => "Franco CFA de Africa Central",
    "codigo" => "XAF",
    "numero" => 950
  },
  {
    "pais" => "CANADA",
    "divisa" => "Dolar canadiense",
    "codigo" => "CAD",
    "numero" => 124
  },
  {
    "pais" => "CHAD",
    "divisa" => "Franco CFA de Africa Central",
    "codigo" => "XAF",
    "numero" => 950
  },
  {
    "pais" => "CHILE",
    "divisa" => "Unidad de Fomento",
    "codigo" => "CLF",
    "numero" => 990
  },
  {
    "pais" => "CHILE",
    "divisa" => "Peso chileno",
    "codigo" => "CLP",
    "numero" => 152
  },
  {
    "pais" => "CHINA",
    "divisa" => "Renminbi",
    "codigo" => "CNY",
    "numero" => 156
  },
  {
    "pais" => "CHIPRE",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "COLOMBIA",
    "divisa" => "Peso colombiano",
    "codigo" => "COP",
    "numero" => 170
  },
  {
    "pais" => "COLOMBIA",
    "divisa" => "Unidad de valor real",
    "codigo" => "COU",
    "numero" => 970
  },
  {
    "pais" => "COMORAS",
    "divisa" => "Franco comorense",
    "codigo" => "KMF",
    "numero" => 174
  },
  {
    "pais" => "CONGO (EL)",
    "divisa" => "Franco CFA de Africa Central",
    "codigo" => "XAF",
    "numero" => 950
  },
  {
    "pais" => "CONGO (REPUBLICA DEMOCRATIC DEL)",
    "divisa" => "Franco congoleno",
    "codigo" => "CDF",
    "numero" => 976
  },
  {
    "pais" => "COSTA DE MARFIL",
    "divisa" => "Franco CFA de Africa Occidental",
    "codigo" => "XOF",
    "numero" => 952
  },
  {
    "pais" => "COSTA RICA",
    "divisa" => "Colon costarricense",
    "codigo" => "CRC",
    "numero" => 188
  },
  {
    "pais" => "CROACIA",
    "divisa" => "Kuna",
    "codigo" => "HRK",
    "numero" => 191
  },
  {
    "pais" => "CUBA",
    "divisa" => "Peso convertible",
    "codigo" => "CUC",
    "numero" => 931
  },
  {
    "pais" => "CUBA",
    "divisa" => "Peso cubano",
    "codigo" => "CUP",
    "numero" => 192
  },
  {
    "pais" => "CURAZAO",
    "divisa" => "Florin antillano neerlandes",
    "codigo" => "ANG",
    "numero" => 532
  },
  {
    "pais" => "DINAMARCA",
    "divisa" => "Corona danesa",
    "codigo" => "DKK",
    "numero" => 208
  },
  {
    "pais" => "DOMINICA",
    "divisa" => "Dolar del Caribe Oriental",
    "codigo" => "XCD",
    "numero" => 951
  },
  {
    "pais" => "ECUADOR",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "EGIPTO",
    "divisa" => "Libra egipcia",
    "codigo" => "EGP",
    "numero" => 818
  },
  {
    "pais" => "EL SALVADOR",
    "divisa" => "Colon",
    "codigo" => "SVC",
    "numero" => 222
  },
  {
    "pais" => "EL SALVADOR",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "EMIRATOS ARABES UNIDOS",
    "divisa" => "Dirham DE EAU",
    "codigo" => "AED",
    "numero" => 784
  },
  {
    "pais" => "ERITREA",
    "divisa" => "Nakfa",
    "codigo" => "ERN",
    "numero" => 232
  },
  {
    "pais" => "ESLOVAQUIA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "ESLOVENIA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "ESPANA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "ESTADO DE PALESTINA",
    "divisa" => "Sin divisa universal",
    "codigo" => "",
    "numero" => ""
  },
  {
    "pais" => "ESTADOS UNIDOS DE AMERICA",
    "divisa" => "Dolar estadounidense (Next day)",
    "codigo" => "USN",
    "numero" => 997
  },
  {
    "pais" => "ESTONIA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "ETIOPIA",
    "divisa" => "Birr etiope",
    "codigo" => "ETB",
    "numero" => 230
  },
  {
    "pais" => "FIJI",
    "divisa" => "Dolar fiyiano",
    "codigo" => "FJD",
    "numero" => 242
  },
  {
    "pais" => "FILIPINAS",
    "divisa" => "Peso filipino",
    "codigo" => "PHP",
    "numero" => 608
  },
  {
    "pais" => "FINLANDIA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "FONDO MONETARIO INTERNACIONAL",
    "divisa" => "SDR (Derecho Especial de Retiro)",
    "codigo" => "XDR",
    "numero" => 960
  },
  {
    "pais" => "FRANCIA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "GABON",
    "divisa" => "Franco CFA de Africa Central",
    "codigo" => "XAF",
    "numero" => 950
  },
  {
    "pais" => "GAMBIA",
    "divisa" => "Dalasi",
    "codigo" => "GMD",
    "numero" => 270
  },
  {
    "pais" => "GEORGIA",
    "divisa" => "Lari",
    "codigo" => "GEL",
    "numero" => 981
  },
  {
    "pais" => "GHANA",
    "divisa" => "Cedi",
    "codigo" => "GHS",
    "numero" => 936
  },
  {
    "pais" => "GIBRALTAR",
    "divisa" => "Libra gibraltarena",
    "codigo" => "GIP",
    "numero" => 292
  },
  {
    "pais" => "GRANADA",
    "divisa" => "Dolar del Caribe Oriental",
    "codigo" => "XCD",
    "numero" => 951
  },
  {
    "pais" => "GRECIA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "GROENLANDIA",
    "divisa" => "Corona danesa",
    "codigo" => "DKK",
    "numero" => 208
  },
  {
    "pais" => "GUADALUPE",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "GUAM",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "GUATEMALA",
    "divisa" => "Quetzal",
    "codigo" => "GTQ",
    "numero" => 320
  },
  {
    "pais" => "GUERNSEY",
    "divisa" => "Libra esterlina",
    "codigo" => "GBP",
    "numero" => 826
  },
  {
    "pais" => "GUINEA",
    "divisa" => "Franco guineano",
    "codigo" => "GNF",
    "numero" => 324
  },
  {
    "pais" => "GUINEA ECUATORIAL",
    "divisa" => "Franco CFA de Africa Central",
    "codigo" => "XAF",
    "numero" => 950
  },
  {
    "pais" => "GUINEA-BISSAU",
    "divisa" => "Franco CFA de Africa Occidental",
    "codigo" => "XOF",
    "numero" => 952
  },
  {
    "pais" => "GUYANA",
    "divisa" => "Dolar guyanes",
    "codigo" => "GYD",
    "numero" => 328
  },
  {
    "pais" => "GUYANA FRANCESA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "HAITI",
    "divisa" => "Gourde",
    "codigo" => "HTG",
    "numero" => 332
  },
  {
    "pais" => "HAITI",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "HOLANDA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "HONDURAS",
    "divisa" => "Lempira",
    "codigo" => "HNL",
    "numero" => 340
  },
  {
    "pais" => "HONG KONG",
    "divisa" => "Dolar de Hong Kong",
    "codigo" => "HKD",
    "numero" => 344
  },
  {
    "pais" => "HUNGRIA",
    "divisa" => "Forinto hungaro",
    "codigo" => "HUF",
    "numero" => 348
  },
  {
    "pais" => "INDIA",
    "divisa" => "Rupia india",
    "codigo" => "INR",
    "numero" => 356
  },
  {
    "pais" => "INDONESIA",
    "divisa" => "Rupia indonesia",
    "codigo" => "IDR",
    "numero" => 360
  },
  {
    "pais" => "IRAK",
    "divisa" => "Dinar iraqui",
    "codigo" => "IQD",
    "numero" => 368
  },
  {
    "pais" => "IRLANDA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "ISLA BOUVET",
    "divisa" => "Corona noruega",
    "codigo" => "NOK",
    "numero" => 578
  },
  {
    "pais" => "ISLA DE MAN",
    "divisa" => "Libra esterlina",
    "codigo" => "GBP",
    "numero" => 826
  },
  {
    "pais" => "ISLA DE NAVIDAD",
    "divisa" => "Dolar australiano",
    "codigo" => "AUD",
    "numero" => 36
  },
  {
    "pais" => "ISLA NORFOLK",
    "divisa" => "Dolar australiano",
    "codigo" => "AUD",
    "numero" => 36
  },
  {
    "pais" => "ISLANDIA",
    "divisa" => "Corona islandesa",
    "codigo" => "ISK",
    "numero" => 352
  },
  {
    "pais" => "ISLAS CAIMAN (LAS)",
    "divisa" => "Dolar de las Islas Cayman",
    "codigo" => "KYD",
    "numero" => 136
  },
  {
    "pais" => "ISLAS COCOS (KEELING)",
    "divisa" => "Dolar australiano",
    "codigo" => "AUD",
    "numero" => 36
  },
  {
    "pais" => "ISLAS COOK (LAS)",
    "divisa" => "Dolar de la Islas Cook",
    "codigo" => "NZD",
    "numero" => 554
  },
  {
    "pais" => "ISLAS FAROE",
    "divisa" => "Corona danesa",
    "codigo" => "DKK",
    "numero" => 208
  },
  {
    "pais" => "ISLAS GEORGIA DEL SUR Y SANDWICH DEL SUR",
    "divisa" => "Sin divisa universal",
    "codigo" => "",
    "numero" => ""
  },
  {
    "pais" => "ISLAS HEARD Y McDONALD",
    "divisa" => "Dolar australiano",
    "codigo" => "AUD",
    "numero" => 36
  },
  {
    "pais" => "ISLAS MALVINAS",
    "divisa" => "Libra malvinense",
    "codigo" => "FKP",
    "numero" => 238
  },
  {
    "pais" => "ISLAS MARIANS DEL NORTE",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "ISLAS MARSHALL",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "ISLAS SALOMON",
    "divisa" => "Dolar de Islas Salomon",
    "codigo" => "SBD",
    "numero" => 90
  },
  {
    "pais" => "ISLAS SVALBARD Y JAN MAYEN",
    "divisa" => "Corona noruega",
    "codigo" => "NOK",
    "numero" => 578
  },
  {
    "pais" => "ISLAS TURCOS Y CAICOS",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "ISLAS ULTRAMARINAS MENORES DE EE. UU.",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "ISLAS VIRGENES (EEUU)",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "ISLAS VIRGENES BRITANICAS",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "ISLAS ÅLAND",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "ISRAEL",
    "divisa" => "Nuevo sequel",
    "codigo" => "ILS",
    "numero" => 376
  },
  {
    "pais" => "ITALIA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "JAMAICA",
    "divisa" => "Dolar jamaiquino",
    "codigo" => "JMD",
    "numero" => 388
  },
  {
    "pais" => "JAPON",
    "divisa" => "Yen",
    "codigo" => "JPY",
    "numero" => 392
  },
  {
    "pais" => "JERSEY",
    "divisa" => "Libra esterlina",
    "codigo" => "GBP",
    "numero" => 826
  },
  {
    "pais" => "JORDANIA",
    "divisa" => "Dinar jordano",
    "codigo" => "JOD",
    "numero" => 400
  },
  {
    "pais" => "KAZAJISTAN",
    "divisa" => "Tenge kazajo",
    "codigo" => "KZT",
    "numero" => 398
  },
  {
    "pais" => "KENIA",
    "divisa" => "Chelin keniano",
    "codigo" => "KES",
    "numero" => 404
  },
  {
    "pais" => "KIRGUISTAN",
    "divisa" => "Som",
    "codigo" => "KGS",
    "numero" => 417
  },
  {
    "pais" => "KIRIBATI",
    "divisa" => "Dolar australiano",
    "codigo" => "AUD",
    "numero" => 36
  },
  {
    "pais" => "KUWAIT",
    "divisa" => "Dinar kuwaiti",
    "codigo" => "KWD",
    "numero" => 414
  },
  {
    "pais" => "LESOTO",
    "divisa" => "Loti",
    "codigo" => "LSL",
    "numero" => 426
  },
  {
    "pais" => "LESOTO",
    "divisa" => "Rand",
    "codigo" => "ZAR",
    "numero" => 710
  },
  {
    "pais" => "LETONIA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "LIBERIA",
    "divisa" => "Dolar liberiano",
    "codigo" => "LRD",
    "numero" => 430
  },
  {
    "pais" => "LIBIA",
    "divisa" => "Dinar libio",
    "codigo" => "LYD",
    "numero" => 434
  },
  {
    "pais" => "LIECHTENSTEIN",
    "divisa" => "Franco suizo",
    "codigo" => "CHF",
    "numero" => 756
  },
  {
    "pais" => "LITUANIA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "LUXEMBURGO",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "LIBANO",
    "divisa" => "Libra libanesa",
    "codigo" => "LBP",
    "numero" => 422
  },
  {
    "pais" => "MACAO",
    "divisa" => "Pataca",
    "codigo" => "MOP",
    "numero" => 446
  },
  {
    "pais" => "MACEDONIA",
    "divisa" => "Dinar",
    "codigo" => "MKD",
    "numero" => 807
  },
  {
    "pais" => "MADAGASCAR",
    "divisa" => "Ariary malgache",
    "codigo" => "MGA",
    "numero" => 969
  },
  {
    "pais" => "MALASIA",
    "divisa" => "Ringgit malayo",
    "codigo" => "MYR",
    "numero" => 458
  },
  {
    "pais" => "MALAWI",
    "divisa" => "Kwacha malaui",
    "codigo" => "MWK",
    "numero" => 454
  },
  {
    "pais" => "MALDIVAS",
    "divisa" => "Rupia de maldivas",
    "codigo" => "MVR",
    "numero" => 462
  },
  {
    "pais" => "MALTA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "MALI",
    "divisa" => "Franco CFA de Africa Occidental",
    "codigo" => "XOF",
    "numero" => 952
  },
  {
    "pais" => "MARRUECOS",
    "divisa" => "Dirham marroqui",
    "codigo" => "MAD",
    "numero" => 504
  },
  {
    "pais" => "MARTINICA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "MAURICIO",
    "divisa" => "Rupia de Mauricio",
    "codigo" => "MUR",
    "numero" => 480
  },
  {
    "pais" => "MAURITANIA",
    "divisa" => "Uguiya",
    "codigo" => "MRO",
    "numero" => 478
  },
  {
    "pais" => "MAYOTTE",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "MICRONESIA",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "MONGOLIA",
    "divisa" => "Tugrik",
    "codigo" => "MNT",
    "numero" => 496
  },
  {
    "pais" => "MONTENEGRO",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "MONTSERRAT",
    "divisa" => "Dolar del Caribe oriental",
    "codigo" => "XCD",
    "numero" => 951
  },
  {
    "pais" => "MOZAMBIQUE",
    "divisa" => "Metical mozambiqueno",
    "codigo" => "MZN",
    "numero" => 943
  },
  {
    "pais" => "MEXICO",
    "divisa" => "Peso mexicano",
    "codigo" => "MXN",
    "numero" => 484
  },
  {
    "pais" => "MEXICO",
    "divisa" => "Unidad de Inversion Mexicana(UDI)",
    "codigo" => "MXV",
    "numero" => 979
  },
  {
    "pais" => "MONACO",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "NAMIBIA",
    "divisa" => "Dolar de Namibia",
    "codigo" => "NAD",
    "numero" => 516
  },
  {
    "pais" => "NAMIBIA",
    "divisa" => "Rand",
    "codigo" => "ZAR",
    "numero" => 710
  },
  {
    "pais" => "NAURU",
    "divisa" => "Dolar australiano",
    "codigo" => "AUD",
    "numero" => 36
  },
  {
    "pais" => "NEPAL",
    "divisa" => "Rupia nepali",
    "codigo" => "NPR",
    "numero" => 524
  },
  {
    "pais" => "NICARAGUA",
    "divisa" => "Cordoba oro",
    "codigo" => "NIO",
    "numero" => 558
  },
  {
    "pais" => "NIGERIA",
    "divisa" => "Franco CFA de Africa Occidental",
    "codigo" => "XOF",
    "numero" => 952
  },
  {
    "pais" => "NIGERIA",
    "divisa" => "Naira",
    "codigo" => "NGN",
    "numero" => 566
  },
  {
    "pais" => "NIUE",
    "divisa" => "Dolar neozelandes",
    "codigo" => "NZD",
    "numero" => 554
  },
  {
    "pais" => "NORUEGA",
    "divisa" => "Corona noruega",
    "codigo" => "NOK",
    "numero" => 578
  },
  {
    "pais" => "NUEVA CALEDONIA",
    "divisa" => "Franco CFP",
    "codigo" => "XPF",
    "numero" => 953
  },
  {
    "pais" => "NUEVA ZELANDA",
    "divisa" => "Dolar neozelandes",
    "codigo" => "NZD",
    "numero" => 554
  },
  {
    "pais" => "OMAN",
    "divisa" => "Rial omani",
    "codigo" => "OMR",
    "numero" => 512
  },
  {
    "pais" => "PAISES MIEMBROS DEL BANCO AFRICANO DE DESARROLLO",
    "divisa" => "BAD UNIDAD DE CUENTAS",
    "codigo" => "XUA",
    "numero" => 965
  },
  {
    "pais" => "PAKISTAN",
    "divisa" => "Rupia pakistani",
    "codigo" => "PKR",
    "numero" => 586
  },
  {
    "pais" => "PALAU",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "PANAMA",
    "divisa" => "Balboa",
    "codigo" => "PAB",
    "numero" => 590
  },
  {
    "pais" => "PANAMA",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "PAPUA NUEVA GUINEA",
    "divisa" => "Kina",
    "codigo" => "PGK",
    "numero" => 598
  },
  {
    "pais" => "PARAGUAY",
    "divisa" => "Guarani",
    "codigo" => "PYG",
    "numero" => 600
  },
  {
    "pais" => "PERU",
    "divisa" => "Nuevo Sol",
    "codigo" => "PEN",
    "numero" => 604
  },
  {
    "pais" => "PITCAIRN",
    "divisa" => "Dolar neozelandes",
    "codigo" => "NZD",
    "numero" => 554
  },
  {
    "pais" => "POLINESIA FRANCESA",
    "divisa" => "Franco CFP",
    "codigo" => "XPF",
    "numero" => 953
  },
  {
    "pais" => "POLONIA",
    "divisa" => "Zloty",
    "codigo" => "PLN",
    "numero" => 985
  },
  {
    "pais" => "PORTUGAL",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "PUERTO RICO",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "QATAR",
    "divisa" => "Riyal catari",
    "codigo" => "QAR",
    "numero" => 634
  },
  {
    "pais" => "REINO UNIDO DE GRAN BRETANA E IRLANDA DEL NORTE",
    "divisa" => "Libra esterlina",
    "codigo" => "GBP",
    "numero" => 826
  },
  {
    "pais" => "REPUBLICA DEMOCRATICA POPULAR LAO",
    "divisa" => "Kip laosiano",
    "codigo" => "LAK",
    "numero" => 418
  },
    {
    "pais" => "REPUBLICA CENTROAFRICANA (LA)",
    "divisa" => "Franco CFA de Africa Central",
    "codigo" => "XAF",
    "numero" => 950
  },
  {
    "pais" => "REPUBLICA CHECA",
    "divisa" => "Czech Koruna",
    "codigo" => "CZK",
    "numero" => 203
  },
  {
    "pais" => "REPUBLICA DE COREA DEL SUR",
    "divisa" => "Won",
    "codigo" => "KRW",
    "numero" => 410
  },
  {
    "pais" => "REPUBLICA DE MOLDAVIA",
    "divisa" => "Leu Moldavo",
    "codigo" => "MDL",
    "numero" => 498
  },
  {
    "pais" => "REPUBLICA DEMOCRATICA DE COREA DEL NORTE",
    "divisa" => "Won norcoreano",
    "codigo" => "KPW",
    "numero" => 408
  },
  {
    "pais" => "REPUBLICA DOMINICANA",
    "divisa" => "Peso dominicano",
    "codigo" => "DOP",
    "numero" => 214
  },
  {
    "pais" => "REPUBLICA ISLAMICA DE IRAN",
    "divisa" => "Rial irani",
    "codigo" => "IRR",
    "numero" => 364
  },
  {
    "pais" => "REPUBLICA UNIDA DE TANZANIA",
    "divisa" => "Chelin tanzano",
    "codigo" => "TZS",
    "numero" => 834
  },
  {
    "pais" => "REPUBLICA ARABE SIRIA",
    "divisa" => "Libra siria",
    "codigo" => "SYP",
    "numero" => 760
  },
  {
    "pais" => "REUNION",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "RUANDA",
    "divisa" => "Franco ruandes",
    "codigo" => "RWF",
    "numero" => 646
  },
  {
    "pais" => "RUMANIA",
    "divisa" => "Leu rumano",
    "codigo" => "RON",
    "numero" => 946
  },
  {
    "pais" => "RUSIA",
    "divisa" => "Rublo ruso",
    "codigo" => "RUB",
    "numero" => 643
  },
  {
    "pais" => "SAHARA OCCIDENTAL",
    "divisa" => "Dirham marroqui",
    "codigo" => "MAD",
    "numero" => 504
  },
  {
    "pais" => "SAMOA",
    "divisa" => "Tala",
    "codigo" => "WST",
    "numero" => 882
  },
  {
    "pais" => "SAMOA AMERICANA",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "SAN BARTOLOME",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "SAN CRISTOBAL Y NIEVES",
    "divisa" => "Dolar del Caribe oriental",
    "codigo" => "XCD",
    "numero" => 951
  },
  {
    "pais" => "SAN MARINO",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "SAN MARTIN",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "SAN MARTIN (PARTE HOLANDESA)",
    "divisa" => "Florin holandes",
    "codigo" => "ANG",
    "numero" => 532
  },
  {
    "pais" => "SAN PEDRO Y MIQUELON",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "SAN TOME Y PRINCIPE",
    "divisa" => "Dobra",
    "codigo" => "STD",
    "numero" => 678
  },
  {
    "pais" => "SAN VICENTE Y LAS GRANADINAS",
    "divisa" => "Dolar del Caribe oriental",
    "codigo" => "XCD",
    "numero" => 951
  },
  {
    "pais" => "SANTA HELENA ASCENCION Y TRISTAN DE ACUNA",
    "divisa" => "Libra de Santa Helena",
    "codigo" => "SHP",
    "numero" => 654
  },
  {
    "pais" => "SANTA LUCIA",
    "divisa" => "Dolar del Caribe oriental",
    "codigo" => "XCD",
    "numero" => 951
  },
  {
    "pais" => "SANTA SEDE",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "SENEGAL",
    "divisa" => "Franco CFA de Africa Occidental",
    "codigo" => "XOF",
    "numero" => 952
  },
  {
    "pais" => "SERBIA",
    "divisa" => "Dinar serbio",
    "codigo" => "RSD",
    "numero" => 941
  },
  {
    "pais" => "SEYCHELLES",
    "divisa" => "Rupia de Seychelles",
    "codigo" => "SCR",
    "numero" => 690
  },
  {
    "pais" => "SIERRA LEONA",
    "divisa" => "Leone",
    "codigo" => "SLL",
    "numero" => 694
  },
  {
    "pais" => "SINGAPUR",
    "divisa" => "Dolar de Singapur",
    "codigo" => "SGD",
    "numero" => 702
  },
  {
    "pais" => "SISTEMA UNITARIO DE COMPENSACION REGIONAL DE PAGOS \"SUCRE",
    "divisa" => "Sucre",
    "codigo" => "XSU",
    "numero" => 994
  },
  {
    "pais" => "SOMALIA",
    "divisa" => "Chelin somali",
    "codigo" => "SOS",
    "numero" => 706
  },
  {
    "pais" => "SRI LANKA",
    "divisa" => "Rupia de Sri Lanka",
    "codigo" => "LKR",
    "numero" => 144
  },
  {
    "pais" => "SUAZILANDIA",
    "divisa" => "Lilangeni",
    "codigo" => "SZL",
    "numero" => 748
  },
  {
    "pais" => "SUDAFRICA",
    "divisa" => "Rand",
    "codigo" => "ZAR",
    "numero" => 710
  },
  {
    "pais" => "SUDAN",
    "divisa" => "Libra sudanesa",
    "codigo" => "SDG",
    "numero" => 938
  },
  {
    "pais" => "SUDAN DEL SUR",
    "divisa" => "Libra sursudanesa",
    "codigo" => "SSP",
    "numero" => 728
  },
  {
    "pais" => "SUECIA",
    "divisa" => "Corona sueca",
    "codigo" => "SEK",
    "numero" => 752
  },
  {
    "pais" => "SUIZA",
    "divisa" => "WIR Euro",
    "codigo" => "CHE",
    "numero" => 947
  },
  {
    "pais" => "SUIZA",
    "divisa" => "Franco suizo",
    "codigo" => "CHF",
    "numero" => 756
  },
  {
    "pais" => "SUIZA",
    "divisa" => "Franco WIR",
    "codigo" => "CHW",
    "numero" => 948
  },
  {
    "pais" => "SURINAM",
    "divisa" => "Dolar de Surinam",
    "codigo" => "SRD",
    "numero" => 968
  },
  {
    "pais" => "TAILANDIA",
    "divisa" => "Baht",
    "codigo" => "THB",
    "numero" => 764
  },
  {
    "pais" => "TAIWAN (PROVINCIA DE CHINA)",
    "divisa" => "Nuevo dolar de Taiwán",
    "codigo" => "TWD",
    "numero" => 901
  },
  {
    "pais" => "TAJIKISTAN",
    "divisa" => "Somoni",
    "codigo" => "TJS",
    "numero" => 972
  },
  {
    "pais" => "TERRITORIO BRITANICO DEL OCEANO INDICO",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "TERRITORIOS AUSTRALES FRANCESES",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "TIMOR ORIENTAL",
    "divisa" => "Dolar estadounidense",
    "codigo" => "USD",
    "numero" => 840
  },
  {
    "pais" => "TOGO",
    "divisa" => "Franco CFA de Africa Occidental",
    "codigo" => "XOF",
    "numero" => 952
  },
  {
    "pais" => "TOKELAU",
    "divisa" => "Dolar neozelandes",
    "codigo" => "NZD",
    "numero" => 554
  },
  {
    "pais" => "TONGA",
    "divisa" => "Pa’anga",
    "codigo" => "TOP",
    "numero" => 776
  },
  {
    "pais" => "TRINIDAD Y TOBAGO",
    "divisa" => "Dolar de Trinidad y Tobago",
    "codigo" => "TTD",
    "numero" => 780
  },
  {
    "pais" => "TURMENISTAN",
    "divisa" => "Manat turcomano",
    "codigo" => "TMT",
    "numero" => 934
  },
  {
    "pais" => "TURQUIA",
    "divisa" => "Lira turca",
    "codigo" => "TRY",
    "numero" => 949
  },
  {
    "pais" => "TUVALU",
    "divisa" => "Dolar tuvaluano",
    "codigo" => "AUD",
    "numero" => 36
  },
  {
    "pais" => "TUNEZ",
    "divisa" => "Dinar tunecino",
    "codigo" => "TND",
    "numero" => 788
  },
  {
    "pais" => "UGANDA",
    "divisa" => "Chelin ugandes",
    "codigo" => "UGX",
    "numero" => 800
  },
  {
    "pais" => "UKRANIA",
    "divisa" => "Grivnia",
    "codigo" => "UAH",
    "numero" => 980
  },
  {
    "pais" => "UNION EUROPEA",
    "divisa" => "Euro",
    "codigo" => "EUR",
    "numero" => 978
  },
  {
    "pais" => "URUGUAY",
    "divisa" => "Peso uruguayo en unidades indexadas (URUIURUI)",
    "codigo" => "UYI",
    "numero" => 940
  },
  {
    "pais" => "URUGUAY",
    "divisa" => "Peso uruguayo",
    "codigo" => "UYU",
    "numero" => 858
  },
  {
    "pais" => "UZBEKISTAN",
    "divisa" => "Som uzbeko",
    "codigo" => "UZS",
    "numero" => 860
  },
  {
    "pais" => "VANUATU",
    "divisa" => "Vatu",
    "codigo" => "VUV",
    "numero" => 548
  },
  {
    "pais" => "VIETNAM",
    "divisa" => "Dong",
    "codigo" => "VND",
    "numero" => 704
  },
  {
    "pais" => "WALLIS Y FUTUNA",
    "divisa" => "Franco CFP",
    "codigo" => "XPF",
    "numero" => 953
  },
  {
    "pais" => "YEMEN",
    "divisa" => "Rial yemeni",
    "codigo" => "YER",
    "numero" => 886
  },
  {
    "pais" => "YIBUTI",
    "divisa" => "Franco yibutiano",
    "codigo" => "DJF",
    "numero" => 262
  },
  {
    "pais" => "ZAMBIA",
    "divisa" => "Kwacha zambiano",
    "codigo" => "ZMW",
    "numero" => 967
  },
  {
    "pais" => "ZIMBABUE",
    "divisa" => "Dolar zimbabuense",
    "codigo" => "ZWL",
    "numero" => 932
  },
  {
    "pais" => "Crypto Moneda",
    "divisa" => "Binance",
    "codigo" => "USDT",
    "numero" => 99991
  },
  {
    "pais" => "Crypto Moneda",
    "divisa" => "Bitcoin",
    "codigo" => "BTC",
    "numero" => 99992
  }
]

monedas.each{|mon|
  buscar = Moneda.find_by(abreviatura: mon['codigo'])
  unless buscar.present?
    Moneda.create(pais: mon['pais'], nombre: mon['divisa'], abreviatura: mon['codigo'])
  end
}
