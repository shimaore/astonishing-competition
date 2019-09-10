/* Parses flat-ornament text syntax */

%lex

FLOAT       [0-9]+","(?:[0-9]+)?\b
INTEGER     [0-9]+
STRING1     [']([^'\r\n]*)[']
STRING2     ["]([^"\r\n]*)["]
PATTERN     [/](\d|\?|\.|\.\.|\.\.\.|…)+[/]
NAME        [A-Za-z][\w-]+

%options flex

/* Non-exclusive states */
/* %s none */
/* Exclusive states */
/* %x none */

%%

/* frcgu */

"Conformément à la réglementation"   return 'REGULATORY'
"d'urgences"                         return 'EMERGENCY'
"ne sont pas facturés"               return 'HIDE_CALL'

"Les appels"                         return 'CALLS'
"les appels"                         return 'CALLS'
"sur le réseau"                      return 'CALLED_ONNET'
"vers les fixes"                     return 'CALLED_FIXED'
"vers les fixes"                     return 'CALLED_FIXED'
"vers les mobiles"                   return 'CALLED_MOBILE'
"vers les fixes et les mobiles"      return 'CALLED_FIXED_OR_MOBILE'
"vers"                               return 'TOWARDS'
"en"                                 return 'TOWARDS'
"aux"                                return 'TOWARDS'
"à destination de"                   return 'TOWARDS'
"à destination de la"                return 'TOWARDS'
"à destination du"                   return 'TOWARDS'
"à destination des"                  return 'TOWARDS'
"Appel illimités"                    return 'UNLIMITED'
"dans la limite de"                  return 'ATMOST'
"au plus"                            return 'ATMOST'
"jusqu'à"                            return 'ATMOST'
"heures"                             return 'HOURS'
"mensuels"                           return 'PER_MONTH'
"mensuelles"                         return 'PER_MONTH'
"destinataires"                      return 'CALLEE'
"différents"                         return 'DIFFERENT'
"différentes"                        return 'DIFFERENT'
"par mois"                           return 'PER_CYCLE'
"par facture"                        return 'PER_CYCLE'
"par période de facturation"         return 'PER_CYCLE'
"sont gratuits"                      return 'FREE'
"sont inclus"                        return 'FREE'
"par appel"                          return 'PER_CALL'
"par jour"                           return 'PER_DAY'
"par heure"                          return 'PER_HOUR'
"par semaine"                        return 'PER_WEEK'
"par jour de la semaine"             return 'PER_DAY_OF_WEEK'
"heure"                              return 'HOURS'
"heures"                             return 'HOURS'
"minute"                             return 'MINUTES'
"minutes"                            return 'MINUTES'
"seconde"                            return 'SECONDES'
"secondes"                           return 'SECONDES'

/* Keep list sorted */

/* Extra names */
"France métropolitaine"             yytext = 'fr'; return 'COUNTRY'
"Hong-Kong"                         yytext = 'hk'; return 'COUNTRY'
"Iles Vierges (U.S.)"               yytext = 'vi'; return 'COUNTRY'
"Nouvelle Zélande"                  yytext = 'nz'; return 'COUNTRY'
"Pays Bas"                          yytext = 'nl'; return 'COUNTRY'
"Royaume-Uni"                       yytext = 'uk'; return 'COUNTRY'
"USA"                               yytext = 'us'; return 'COUNTRY'
"Vatican"                           yytext = 'va'; return 'COUNTRY'
"Vénézuéla"                         yytext = 've'; return 'COUNTRY'

/* Some official names from https://www.iso.org/obp/ui/#search */
"Afghanistan"                       yytext = 'AF'; return 'COUNTRY'
"l'Afghanistan"                     yytext = 'AF'; return 'COUNTRY'
"Afrique du Sud"                    yytext = 'ZA'; return 'COUNTRY'
"l'Afrique du Sud"                  yytext = 'ZA'; return 'COUNTRY'
"les Îles Åland"                    yytext = 'AX'; return 'COUNTRY'
"Åland"                             yytext = 'AX'; return 'COUNTRY'
"l'Albanie"                         yytext = 'AL'; return 'COUNTRY'
"Albanie"                           yytext = 'AL'; return 'COUNTRY'
"l'Algérie"                         yytext = 'DZ'; return 'COUNTRY'
"Algérie"                           yytext = 'DZ'; return 'COUNTRY'
"l'Allemagne"                       yytext = 'DE'; return 'COUNTRY'
"Allemagne"                         yytext = 'DE'; return 'COUNTRY'
"Andorre"                           yytext = 'AD'; return 'COUNTRY'
"l'Andorre"                         yytext = 'AD'; return 'COUNTRY'
"l'Angola"                          yytext = 'AO'; return 'COUNTRY'
"Angola"                            yytext = 'AO'; return 'COUNTRY'
"Anguilla"                          yytext = 'AI'; return 'COUNTRY'
"l'Antarctique"                     yytext = 'AQ'; return 'COUNTRY'
"Antarctique"                       yytext = 'AQ'; return 'COUNTRY'
"Antigua-et-Barbuda"                yytext = 'AG'; return 'COUNTRY'
"l'Arabie saoudite"                 yytext = 'SA'; return 'COUNTRY'
"Arabie saoudite"                   yytext = 'SA'; return 'COUNTRY'
"l'Argentine"                       yytext = 'AR'; return 'COUNTRY'
"Argentine"                         yytext = 'AR'; return 'COUNTRY'
"l'Arménie"                         yytext = 'AM'; return 'COUNTRY'
"Arménie"                           yytext = 'AM'; return 'COUNTRY'
"Aruba"                             yytext = 'AW'; return 'COUNTRY'
"l'Australie"                       yytext = 'AU'; return 'COUNTRY'
"Australie"                         yytext = 'AU'; return 'COUNTRY'
"l'Autriche"                        yytext = 'AT'; return 'COUNTRY'
"Autriche"                          yytext = 'AT'; return 'COUNTRY'
"l'Azerbaïdjan"                     yytext = 'AZ'; return 'COUNTRY'
"Azerbaïdjan"                       yytext = 'AZ'; return 'COUNTRY'
"les Bahamas"                       yytext = 'BS'; return 'COUNTRY'
"Bahamas"                           yytext = 'BS'; return 'COUNTRY'
"Bahreïn"                           yytext = 'BH'; return 'COUNTRY'
"le Bangladesh"                     yytext = 'BD'; return 'COUNTRY'
"Bangladesh"                        yytext = 'BD'; return 'COUNTRY'
"la Barbade"                        yytext = 'BB'; return 'COUNTRY'
"Barbade"                           yytext = 'BB'; return 'COUNTRY'
"le Bélarus"                        yytext = 'BY'; return 'COUNTRY'
"Bélarus"                           yytext = 'BY'; return 'COUNTRY'
"la Belgique"                       yytext = 'BE'; return 'COUNTRY'
"Belgique"                          yytext = 'BE'; return 'COUNTRY'
"le Belize"                         yytext = 'BZ'; return 'COUNTRY'
"Belize"                            yytext = 'BZ'; return 'COUNTRY'
"le Bénin"                          yytext = 'BJ'; return 'COUNTRY'
"Bénin"                             yytext = 'BJ'; return 'COUNTRY'
"les Bermudes"                      yytext = 'BM'; return 'COUNTRY'
"Bermudes"                          yytext = 'BM'; return 'COUNTRY'
"le Bhoutan"                        yytext = 'BT'; return 'COUNTRY'
"Bhoutan"                           yytext = 'BT'; return 'COUNTRY'
"État plurinational de Bolivie"     yytext = 'BO'; return 'COUNTRY'
"Bolivie"                           yytext = 'BO'; return 'COUNTRY'
"Bonaire, Saint-Eustache et Saba"   yytext = 'BQ'; return 'COUNTRY'
"la Bosnie-Herzégovine"             yytext = 'BA'; return 'COUNTRY'
"Bosnie-Herzégovine"                yytext = 'BA'; return 'COUNTRY'
"le Botswana"                       yytext = 'BW'; return 'COUNTRY'
"Botswana"                          yytext = 'BW'; return 'COUNTRY'
"l'Île Bouvet"                      yytext = 'BV'; return 'COUNTRY'
"Bouvet"                            yytext = 'BV'; return 'COUNTRY'
"le Brésil"                         yytext = 'BR'; return 'COUNTRY'
"Brésil"                            yytext = 'BR'; return 'COUNTRY'
"le Brunéi Darussalam"              yytext = 'BN'; return 'COUNTRY'
"Brunéi Darussalam"                 yytext = 'BN'; return 'COUNTRY'
"la Bulgarie"                       yytext = 'BG'; return 'COUNTRY'
"Bulgarie"                          yytext = 'BG'; return 'COUNTRY'
"le Burkina Faso"                   yytext = 'BF'; return 'COUNTRY'
"Burkina Faso"                      yytext = 'BF'; return 'COUNTRY'
"le Burundi"                        yytext = 'BI'; return 'COUNTRY'
"Burundi"                           yytext = 'BI'; return 'COUNTRY'
"Cabo Verde"                        yytext = 'CV'; return 'COUNTRY'
"les Îles Caïmans"                  yytext = 'KY'; return 'COUNTRY'
"Caïmans"                           yytext = 'KY'; return 'COUNTRY'
"le Cambodge"                       yytext = 'KH'; return 'COUNTRY'
"Cambodge"                          yytext = 'KH'; return 'COUNTRY'
"le Cameroun"                       yytext = 'CM'; return 'COUNTRY'
"Cameroun"                          yytext = 'CM'; return 'COUNTRY'
"le Canada"                         yytext = 'CA'; return 'COUNTRY'
"Canada"                            yytext = 'CA'; return 'COUNTRY'
"le Chili"                          yytext = 'CL'; return 'COUNTRY'
"Chili"                             yytext = 'CL'; return 'COUNTRY'
"la Chine"                          yytext = 'CN'; return 'COUNTRY'
"Chine"                             yytext = 'CN'; return 'COUNTRY'
"l'Île Christmas"                   yytext = 'CX'; return 'COUNTRY'
"Christmas"                         yytext = 'CX'; return 'COUNTRY'
"Chypre"                            yytext = 'CY'; return 'COUNTRY'
"les Îles Cocos"                    yytext = 'CC'; return 'COUNTRY'
"les Îles Keeling"                  yytext = 'CC'; return 'COUNTRY'
"Cocos"                             yytext = 'CC'; return 'COUNTRY'
"Keeling"                           yytext = 'CC'; return 'COUNTRY'
"la Colombie"                       yytext = 'CO'; return 'COUNTRY'
"Colombie"                          yytext = 'CO'; return 'COUNTRY'
"les Comores"                       yytext = 'KM'; return 'COUNTRY'
"Comores"                           yytext = 'KM'; return 'COUNTRY'
"la République démocratique du Congo"             yytext = 'CD'; return 'COUNTRY'
"le Congo"                          yytext = 'CG'; return 'COUNTRY'
"Congo"                             yytext = 'CG'; return 'COUNTRY'
"les Îles Cook"                     yytext = 'CK'; return 'COUNTRY'
"Cook"                              yytext = 'CK'; return 'COUNTRY'
"la République de Corée"            yytext = 'KR'; return 'COUNTRY'
"la République populaire démocratique de Corée"   yytext = 'KP'; return 'COUNTRY'
"le Costa Rica"                     yytext = 'CR'; return 'COUNTRY'
"Costa Rica"                        yytext = 'CR'; return 'COUNTRY'
"la Côte d'Ivoire"                  yytext = 'CI'; return 'COUNTRY'
"Côte d'Ivoire"                     yytext = 'CI'; return 'COUNTRY'
"la Croatie"                        yytext = 'HR'; return 'COUNTRY'
"Croatie"                           yytext = 'HR'; return 'COUNTRY'
"Cuba"                              yytext = 'CU'; return 'COUNTRY'
"Curaçao"                           yytext = 'CW'; return 'COUNTRY'
"le Danemark"                       yytext = 'DK'; return 'COUNTRY'
"Danemark"                          yytext = 'DK'; return 'COUNTRY'
"Djibouti"                          yytext = 'DJ'; return 'COUNTRY'
"la République dominicaine"         yytext = 'DO'; return 'COUNTRY'
"la Dominique"                      yytext = 'DM'; return 'COUNTRY'
"Dominique"                         yytext = 'DM'; return 'COUNTRY'
"l'Égypte"                          yytext = 'EG'; return 'COUNTRY'
"Égypte"                            yytext = 'EG'; return 'COUNTRY'
"El Salvador"                       yytext = 'SV'; return 'COUNTRY'
"le Émirats arabes unis"            yytext = 'AE'; return 'COUNTRY'
"Émirats arabes unis"               yytext = 'AE'; return 'COUNTRY'
"l'Équateur"                        yytext = 'EC'; return 'COUNTRY'
"Équateur"                          yytext = 'EC'; return 'COUNTRY'
"l'Érythrée"                        yytext = 'ER'; return 'COUNTRY'
"Érythrée"                          yytext = 'ER'; return 'COUNTRY'
"l'Espagne"                         yytext = 'ES'; return 'COUNTRY'
"Espagne"                           yytext = 'ES'; return 'COUNTRY'
"l'Estonie"                         yytext = 'EE'; return 'COUNTRY'
"Estonie"                           yytext = 'EE'; return 'COUNTRY'
"l'Eswatini"                        yytext = 'SZ'; return 'COUNTRY'
"Eswatini"                          yytext = 'SZ'; return 'COUNTRY'
"les États-Unis d'Amérique"         yytext = 'US'; return 'COUNTRY'
"États-Unis d'Amérique"             yytext = 'US'; return 'COUNTRY'
"l'Éthiopie"                        yytext = 'ET'; return 'COUNTRY'
"Éthiopie"                          yytext = 'ET'; return 'COUNTRY'
"les Îles Falkland"                 yytext = 'FK'; return 'COUNTRY'
"les Îles Malouines"                yytext = 'FK'; return 'COUNTRY'
"Falkland"                          yytext = 'FK'; return 'COUNTRY'
"Malouines"                         yytext = 'FK'; return 'COUNTRY'
"les Îles Féroé"                    yytext = 'FO'; return 'COUNTRY'
"Féroé"                             yytext = 'FO'; return 'COUNTRY'
"les Fidji"                         yytext = 'FJ'; return 'COUNTRY'
"Fidji"                             yytext = 'FJ'; return 'COUNTRY'
"la Finlande"                       yytext = 'FI'; return 'COUNTRY'
"Finlande"                          yytext = 'FI'; return 'COUNTRY'
"la France"                         yytext = 'FR'; return 'COUNTRY'
"France"                            yytext = 'FR'; return 'COUNTRY'
"le Gabon"                          yytext = 'GA'; return 'COUNTRY'
"Gabon"                             yytext = 'GA'; return 'COUNTRY'
"la Gambie"                         yytext = 'GM'; return 'COUNTRY'
"Gambie"                            yytext = 'GM'; return 'COUNTRY'
"la Géorgie"                        yytext = 'GE'; return 'COUNTRY'
"Géorgie"                           yytext = 'GE'; return 'COUNTRY'
"la Géorgie du Sud-et-les Îles Sandwich du Sud"     yytext = 'GS'; return 'COUNTRY'
"Géorgie du Sud-et-les Îles Sandwich du Sud"        yytext = 'GS'; return 'COUNTRY'
"le Ghana"                          yytext = 'GH'; return 'COUNTRY'
"Ghana"                             yytext = 'GH'; return 'COUNTRY'
"Gibraltar"                         yytext = 'GI'; return 'COUNTRY'
"la Grèce"                          yytext = 'GR'; return 'COUNTRY'
"Grèce"                             yytext = 'GR'; return 'COUNTRY'
"la Grenade"                        yytext = 'GD'; return 'COUNTRY'
"Grenade"                           yytext = 'GD'; return 'COUNTRY'
"le Groenland"                      yytext = 'GL'; return 'COUNTRY'
"Groenland"                         yytext = 'GL'; return 'COUNTRY'
"la Guadeloupe"                     yytext = 'GP'; return 'COUNTRY'
"Guadeloupe"                        yytext = 'GP'; return 'COUNTRY'
"Guam"                              yytext = 'GU'; return 'COUNTRY'
"le Guatemala"                      yytext = 'GT'; return 'COUNTRY'
"Guatemala"                         yytext = 'GT'; return 'COUNTRY'
"Guernesey"                         yytext = 'GG'; return 'COUNTRY'
"la Guinée"                         yytext = 'GN'; return 'COUNTRY'
"Guinée"                            yytext = 'GN'; return 'COUNTRY'
"la Guinée équatoriale"             yytext = 'GQ'; return 'COUNTRY'
"Guinée équatoriale"                yytext = 'GQ'; return 'COUNTRY'
"la Guinée-Bissau"                  yytext = 'GW'; return 'COUNTRY'
"Guinée-Bissau"                     yytext = 'GW'; return 'COUNTRY'
"le Guyana"                         yytext = 'GY'; return 'COUNTRY'
"Guyana"                            yytext = 'GY'; return 'COUNTRY'
"la Guyane française"               yytext = 'GF'; return 'COUNTRY'
"Guyane française"                  yytext = 'GF'; return 'COUNTRY'
"Haïti"                             yytext = 'HT'; return 'COUNTRY'
"l'Île Heard-et-Îles MacDonald"     yytext = 'HM'; return 'COUNTRY'
"Heard-et-Îles MacDonald"           yytext = 'HM'; return 'COUNTRY'
"le Honduras"                       yytext = 'HN'; return 'COUNTRY'
"Honduras"                          yytext = 'HN'; return 'COUNTRY'
"Hong Kong"                         yytext = 'HK'; return 'COUNTRY'
"la Hongrie"                        yytext = 'HU'; return 'COUNTRY'
"Hongrie"                           yytext = 'HU'; return 'COUNTRY'
"Île de Man"                        yytext = 'IM'; return 'COUNTRY'
"les Îles mineures éloignées des États-Unis"        yytext = 'UM'; return 'COUNTRY'
"Îles mineures éloignées des États-Unis"            yytext = 'UM'; return 'COUNTRY'
"l'Inde"                            yytext = 'IN'; return 'COUNTRY'
"Inde"                              yytext = 'IN'; return 'COUNTRY'
"le Territoire britannique de l'océan Indien"       yytext = 'IO'; return 'COUNTRY'
"l'Indonésie"                       yytext = 'ID'; return 'COUNTRY'
"Indonésie"                         yytext = 'ID'; return 'COUNTRY'
"la République Islamique d'Iran"    yytext = 'IR'; return 'COUNTRY'
"République Islamique d'Iran"       yytext = 'IR'; return 'COUNTRY'
"Iran"                              yytext = 'IR'; return 'COUNTRY'
"l'Iraq"                            yytext = 'IQ'; return 'COUNTRY'
"Iraq"                              yytext = 'IQ'; return 'COUNTRY'
"l'Irlande"                         yytext = 'IE'; return 'COUNTRY'
"Irlande"                           yytext = 'IE'; return 'COUNTRY'
"l'Islande"                         yytext = 'IS'; return 'COUNTRY'
"Islande"                           yytext = 'IS'; return 'COUNTRY'
"Israël"                            yytext = 'IL'; return 'COUNTRY'
"l'Italie"                          yytext = 'IT'; return 'COUNTRY'
"Italie"                            yytext = 'IT'; return 'COUNTRY'
"la Jamaïque"                       yytext = 'JM'; return 'COUNTRY'
"Jamaïque"                          yytext = 'JM'; return 'COUNTRY'
"le Japon"                          yytext = 'JP'; return 'COUNTRY'
"Japon"                             yytext = 'JP'; return 'COUNTRY'
"Jersey"                            yytext = 'JE'; return 'COUNTRY'
"la Jordanie"                       yytext = 'JO'; return 'COUNTRY'
"Jordanie"                          yytext = 'JO'; return 'COUNTRY'
"le Kazakhstan"                     yytext = 'KZ'; return 'COUNTRY'
"Kazakhstan"                        yytext = 'KZ'; return 'COUNTRY'
"le Kenya"                          yytext = 'KE'; return 'COUNTRY'
"Kenya"                             yytext = 'KE'; return 'COUNTRY'
"le Kirghizistan"                   yytext = 'KG'; return 'COUNTRY'
"Kirghizistan"                      yytext = 'KG'; return 'COUNTRY'
"Kiribati"                          yytext = 'KI'; return 'COUNTRY'
"le Koweït"                         yytext = 'KW'; return 'COUNTRY'
"Koweït"                            yytext = 'KW'; return 'COUNTRY'
"Lao, République démocratique populaire"                    yytext = 'LA'; return 'COUNTRY'
"le Lesotho"                        yytext = 'LS'; return 'COUNTRY'
"Lesotho"                           yytext = 'LS'; return 'COUNTRY'
"la Lettonie"                       yytext = 'LV'; return 'COUNTRY'
"Lettonie"                          yytext = 'LV'; return 'COUNTRY'
"le Liban"                          yytext = 'LB'; return 'COUNTRY'
"Liban"                             yytext = 'LB'; return 'COUNTRY'
"le Libéria"                        yytext = 'LR'; return 'COUNTRY'
"Libéria"                           yytext = 'LR'; return 'COUNTRY'
"la Libye"                          yytext = 'LY'; return 'COUNTRY'
"Libye"                             yytext = 'LY'; return 'COUNTRY'
"le Liechtenstein"                  yytext = 'LI'; return 'COUNTRY'
"Liechtenstein"                     yytext = 'LI'; return 'COUNTRY'
"la Lituanie"                       yytext = 'LT'; return 'COUNTRY'
"Lituanie"                          yytext = 'LT'; return 'COUNTRY'
"le Luxembourg"                     yytext = 'LU'; return 'COUNTRY'
"Luxembourg"                        yytext = 'LU'; return 'COUNTRY'
"Macao"                             yytext = 'MO'; return 'COUNTRY'
"l'ex‑République yougoslave de Macédoine"                   yytext = 'MK'; return 'COUNTRY'
"Macédoine"                         yytext = 'MK'; return 'COUNTRY'
"Madagascar"                        yytext = 'MG'; return 'COUNTRY'
"la Malaisie"                       yytext = 'MY'; return 'COUNTRY'
"Malaisie"                          yytext = 'MY'; return 'COUNTRY'
"le Malawi"                         yytext = 'MW'; return 'COUNTRY'
"Malawi"                            yytext = 'MW'; return 'COUNTRY'
"les Maldives"                      yytext = 'MV'; return 'COUNTRY'
"Maldives"                          yytext = 'MV'; return 'COUNTRY'
"le Mali"                           yytext = 'ML'; return 'COUNTRY'
"Mali"                              yytext = 'ML'; return 'COUNTRY'
"Malte"                             yytext = 'MT'; return 'COUNTRY'
"les Îles Mariannes du Nord"        yytext = 'MP'; return 'COUNTRY'
"Mariannes du Nord"                 yytext = 'MP'; return 'COUNTRY'
"le Maroc"                          yytext = 'MA'; return 'COUNTRY'
"Maroc"                             yytext = 'MA'; return 'COUNTRY'
"Îles Marshall"                     yytext = 'MH'; return 'COUNTRY'
"Marshall"                          yytext = 'MH'; return 'COUNTRY'
"la Martinique"                     yytext = 'MQ'; return 'COUNTRY'
"Martinique"                        yytext = 'MQ'; return 'COUNTRY'
"Maurice"                           yytext = 'MU'; return 'COUNTRY'
"la Mauritanie"                     yytext = 'MR'; return 'COUNTRY'
"Mauritanie"                        yytext = 'MR'; return 'COUNTRY'
"Mayotte"                           yytext = 'YT'; return 'COUNTRY'
"le Mexique"                        yytext = 'MX'; return 'COUNTRY'
"Mexique"                           yytext = 'MX'; return 'COUNTRY'
"États fédérés de Micronésie"       yytext = 'FM'; return 'COUNTRY'
"Micronésie"                        yytext = 'FM'; return 'COUNTRY'
"République de Moldova"             yytext = 'MD'; return 'COUNTRY'
"Moldova"                           yytext = 'MD'; return 'COUNTRY'
"Moldova, République de"            yytext = 'MD'; return 'COUNTRY'
"Monaco"                            yytext = 'MC'; return 'COUNTRY'
"la Mongolie"                       yytext = 'MN'; return 'COUNTRY'
"Mongolie"                          yytext = 'MN'; return 'COUNTRY'
"le Monténégro"                     yytext = 'ME'; return 'COUNTRY'
"Monténégro"                        yytext = 'ME'; return 'COUNTRY'
"Montserrat"                        yytext = 'MS'; return 'COUNTRY'
"le Mozambique"                     yytext = 'MZ'; return 'COUNTRY'
"Mozambique"                        yytext = 'MZ'; return 'COUNTRY'
"le Myanmar"                        yytext = 'MM'; return 'COUNTRY'
"Myanmar"                           yytext = 'MM'; return 'COUNTRY'
"la Namibie"                        yytext = 'NA'; return 'COUNTRY'
"Namibie"                           yytext = 'NA'; return 'COUNTRY'
"Nauru"                             yytext = 'NR'; return 'COUNTRY'
"le Népal"                          yytext = 'NP'; return 'COUNTRY'
"Népal"                             yytext = 'NP'; return 'COUNTRY'
"le Nicaragua"                      yytext = 'NI'; return 'COUNTRY'
"Nicaragua"                         yytext = 'NI'; return 'COUNTRY'
"le Niger"                          yytext = 'NE'; return 'COUNTRY'
"Niger"                             yytext = 'NE'; return 'COUNTRY'
"le Nigéria"                        yytext = 'NG'; return 'COUNTRY'
"Nigéria"                           yytext = 'NG'; return 'COUNTRY'
"Niue"                              yytext = 'NU'; return 'COUNTRY'
"l'Île Norfolk"                     yytext = 'NF'; return 'COUNTRY'
"Norfolk"                           yytext = 'NF'; return 'COUNTRY'
"la Norvège"                        yytext = 'NO'; return 'COUNTRY'
"Norvège"                           yytext = 'NO'; return 'COUNTRY'
"la Nouvelle-Calédonie"             yytext = 'NC'; return 'COUNTRY'
"Nouvelle-Calédonie"                yytext = 'NC'; return 'COUNTRY'
"la Nouvelle-Zélande"               yytext = 'NZ'; return 'COUNTRY'
"Nouvelle-Zélande"                  yytext = 'NZ'; return 'COUNTRY'
"Oman"                              yytext = 'OM'; return 'COUNTRY'
"l'Ouganda"                         yytext = 'UG'; return 'COUNTRY'
"Ouganda"                           yytext = 'UG'; return 'COUNTRY'
"l'Ouzbékistan"                     yytext = 'UZ'; return 'COUNTRY'
"Ouzbékistan"                       yytext = 'UZ'; return 'COUNTRY'
"le Pakistan"                       yytext = 'PK'; return 'COUNTRY'
"Pakistan"                          yytext = 'PK'; return 'COUNTRY'
"les Palaos"                        yytext = 'PW'; return 'COUNTRY'
"Palaos"                            yytext = 'PW'; return 'COUNTRY'
"État de Palestine, "               yytext = 'PS'; return 'COUNTRY'
"Palestine, État de"                yytext = 'PS'; return 'COUNTRY'
"le Panama"                         yytext = 'PA'; return 'COUNTRY'
"Panama"                            yytext = 'PA'; return 'COUNTRY'
"la Papouasie-Nouvelle-Guinée"      yytext = 'PG'; return 'COUNTRY'
"Papouasie-Nouvelle-Guinée"         yytext = 'PG'; return 'COUNTRY'
"le Paraguay"                       yytext = 'PY'; return 'COUNTRY'
"Paraguay"                          yytext = 'PY'; return 'COUNTRY'
"les Pays-Bas"                      yytext = 'NL'; return 'COUNTRY'
"Pays-Bas"                          yytext = 'NL'; return 'COUNTRY'
"le Pérou"                          yytext = 'PE'; return 'COUNTRY'
"Pérou"                             yytext = 'PE'; return 'COUNTRY'
"les Philippines"                   yytext = 'PH'; return 'COUNTRY'
"Philippines"                       yytext = 'PH'; return 'COUNTRY'
"Pitcairn"                          yytext = 'PN'; return 'COUNTRY'
"la Pologne"                        yytext = 'PL'; return 'COUNTRY'
"Pologne"                           yytext = 'PL'; return 'COUNTRY'
"la Polynésie française"            yytext = 'PF'; return 'COUNTRY'
"Polynésie française"               yytext = 'PF'; return 'COUNTRY'
"Porto Rico"                        yytext = 'PR'; return 'COUNTRY'
"le Portugal"                       yytext = 'PT'; return 'COUNTRY'
"Portugal"                          yytext = 'PT'; return 'COUNTRY'
"le Qatar"                          yytext = 'QA'; return 'COUNTRY'
"Qatar"                             yytext = 'QA'; return 'COUNTRY'
"la République arabe syrienne"      yytext = 'SY'; return 'COUNTRY'
"République arabe syrienne"         yytext = 'SY'; return 'COUNTRY'
"la République centrafricaine"      yytext = 'CF'; return 'COUNTRY'
"République centrafricaine"         yytext = 'CF'; return 'COUNTRY'
"la Réunion"                        yytext = 'RE'; return 'COUNTRY'
"Réunion"                           yytext = 'RE'; return 'COUNTRY'
"la Roumanie"                       yytext = 'RO'; return 'COUNTRY'
"Roumanie"                          yytext = 'RO'; return 'COUNTRY'
"le Royaume-Uni de Grande-Bretagne et d'Irlande du Nord"    yytext = 'GB'; return 'COUNTRY'
"Royaume-Uni de Grande-Bretagne et d'Irlande du Nord"       yytext = 'GB'; return 'COUNTRY'
"la Fédération de Russie"           yytext = 'RU'; return 'COUNTRY'
"Russie"                            yytext = 'RU'; return 'COUNTRY'
"le Rwanda"                         yytext = 'RW'; return 'COUNTRY'
"Rwanda"                            yytext = 'RW'; return 'COUNTRY'
"le Sahara occidental"              yytext = 'EH'; return 'COUNTRY'
"Sahara occidental"                 yytext = 'EH'; return 'COUNTRY'
"Saint-Barthélemy"                  yytext = 'BL'; return 'COUNTRY'
"Saint-Kitts-et-Nevis"              yytext = 'KN'; return 'COUNTRY'
"Saint-Marin"                       yytext = 'SM'; return 'COUNTRY'
"Saint-Martin"                      yytext = 'MF'; return 'COUNTRY'
"Saint-Martin"                      yytext = 'SX'; return 'COUNTRY'
"Saint-Pierre-et-Miquelon"          yytext = 'PM'; return 'COUNTRY'
"le Saint-Siège"                    yytext = 'VA'; return 'COUNTRY'
"Saint-Siège"                       yytext = 'VA'; return 'COUNTRY'
"Saint-Vincent-et-les Grenadines"   yytext = 'VC'; return 'COUNTRY'
"Sainte-Hélène, Ascension et Tristan da Cunha"     yytext = 'SH'; return 'COUNTRY'
"Sainte-Lucie"                      yytext = 'LC'; return 'COUNTRY'
"Îles Salomon"                      yytext = 'SB'; return 'COUNTRY'
"Salomon"                           yytext = 'SB'; return 'COUNTRY'
"le Samoa"                          yytext = 'WS'; return 'COUNTRY'
"Samoa"                             yytext = 'WS'; return 'COUNTRY'
"les Samoa américaines"             yytext = 'AS'; return 'COUNTRY'
"Samoa américaines"                 yytext = 'AS'; return 'COUNTRY'
"Sao Tomé-et-Principe"              yytext = 'ST'; return 'COUNTRY'
"le Sénégal"                        yytext = 'SN'; return 'COUNTRY'
"Sénégal"                           yytext = 'SN'; return 'COUNTRY'
"la Serbie"                         yytext = 'RS'; return 'COUNTRY'
"Serbie"                            yytext = 'RS'; return 'COUNTRY'
"les Seychelles"                    yytext = 'SC'; return 'COUNTRY'
"Seychelles"                        yytext = 'SC'; return 'COUNTRY'
"la Sierra Leone"                   yytext = 'SL'; return 'COUNTRY'
"Sierra Leone"                      yytext = 'SL'; return 'COUNTRY'
"Singapour"                         yytext = 'SG'; return 'COUNTRY'
"la Slovaquie"                      yytext = 'SK'; return 'COUNTRY'
"Slovaquie"                         yytext = 'SK'; return 'COUNTRY'
"la Slovénie"                       yytext = 'SI'; return 'COUNTRY'
"Slovénie"                          yytext = 'SI'; return 'COUNTRY'
"la Somalie"                        yytext = 'SO'; return 'COUNTRY'
"Somalie"                           yytext = 'SO'; return 'COUNTRY'
"le Soudan"                         yytext = 'SD'; return 'COUNTRY'
"Soudan"                            yytext = 'SD'; return 'COUNTRY'
"le Soudan du Sud"                  yytext = 'SS'; return 'COUNTRY'
"Soudan du Sud"                     yytext = 'SS'; return 'COUNTRY'
"Sri Lanka"                         yytext = 'LK'; return 'COUNTRY'
"la Suède"                          yytext = 'SE'; return 'COUNTRY'
"Suède"                             yytext = 'SE'; return 'COUNTRY'
"la Suisse"                         yytext = 'CH'; return 'COUNTRY'
"Suisse"                            yytext = 'CH'; return 'COUNTRY'
"le Suriname"                       yytext = 'SR'; return 'COUNTRY'
"Suriname"                          yytext = 'SR'; return 'COUNTRY'
"le Svalbard et l'Île Jan Mayen"    yytext = 'SJ'; return 'COUNTRY'
"Svalbard et l'Île Jan Mayen"       yytext = 'SJ'; return 'COUNTRY'
"le Tadjikistan"                    yytext = 'TJ'; return 'COUNTRY'
"Tadjikistan"                       yytext = 'TJ'; return 'COUNTRY'
"Taïwan"                            yytext = 'TW'; return 'COUNTRY'
"Taïwan, Province de Chine"         yytext = 'TW'; return 'COUNTRY'
"République-Unie de Tanzanie"       yytext = 'TZ'; return 'COUNTRY'
"Tanzanie"                          yytext = 'TZ'; return 'COUNTRY'
"le Tchad"                          yytext = 'TD'; return 'COUNTRY'
"Tchad"                             yytext = 'TD'; return 'COUNTRY'
"la Tchéquie"                       yytext = 'CZ'; return 'COUNTRY'
"Tchéquie"                          yytext = 'CZ'; return 'COUNTRY'
"les Terres australes françaises"   yytext = 'TF'; return 'COUNTRY'
"Terres australes françaises"       yytext = 'TF'; return 'COUNTRY'
"la Thaïlande"                      yytext = 'TH'; return 'COUNTRY'
"Thaïlande"                         yytext = 'TH'; return 'COUNTRY'
"le Timor-Leste"                    yytext = 'TL'; return 'COUNTRY'
"Timor-Leste"                       yytext = 'TL'; return 'COUNTRY'
"Togo"                              yytext = 'TG'; return 'COUNTRY'
"le Togo"                           yytext = 'TG'; return 'COUNTRY'
"Tokelau"                           yytext = 'TK'; return 'COUNTRY'
"les Tokelau"                       yytext = 'TK'; return 'COUNTRY'
"Tonga"                             yytext = 'TO'; return 'COUNTRY'
"les Tonga"                         yytext = 'TO'; return 'COUNTRY'
"Trinité-et-Tobago"                 yytext = 'TT'; return 'COUNTRY'
"la Trinité-et-Tobago"              yytext = 'TT'; return 'COUNTRY'
"Tunisie"                           yytext = 'TN'; return 'COUNTRY'
"la Tunisie"                        yytext = 'TN'; return 'COUNTRY'
"Turkménistan"                      yytext = 'TM'; return 'COUNTRY'
"le Turkménistan"                   yytext = 'TM'; return 'COUNTRY'
"Turks-et-Caïcos"                   yytext = 'TC'; return 'COUNTRY'
"les Îles Turks-et-Caïcos"          yytext = 'TC'; return 'COUNTRY'
"Turquie"                           yytext = 'TR'; return 'COUNTRY'
"la Turquie"                        yytext = 'TR'; return 'COUNTRY'
"Tuvalu"                            yytext = 'TV'; return 'COUNTRY'
"les Tuvalu"                        yytext = 'TV'; return 'COUNTRY'
"Ukraine"                           yytext = 'UA'; return 'COUNTRY'
"l'Ukraine"                         yytext = 'UA'; return 'COUNTRY'
"Uruguay"                           yytext = 'UY'; return 'COUNTRY'
"l'Uruguay"                         yytext = 'UY'; return 'COUNTRY'
"Vanuatu"                           yytext = 'VU'; return 'COUNTRY'
"le Vanuatu"                        yytext = 'VU'; return 'COUNTRY'
"Venezuela"                         yytext = 'VE'; return 'COUNTRY'
"République bolivarienne du Venezuela"              yytext = 'VE'; return 'COUNTRY'
"Vierges britanniques"              yytext = 'VG'; return 'COUNTRY'
"les Îles Vierges britanniques"     yytext = 'VG'; return 'COUNTRY'
"Vierges des États-Unis"            yytext = 'VI'; return 'COUNTRY'
"les Îles Vierges des États-Unis"   yytext = 'VI'; return 'COUNTRY'
"Viet Nam"                          yytext = 'VN'; return 'COUNTRY'
"le Viet Nam"                       yytext = 'VN'; return 'COUNTRY'
"Wallis-et-Futuna"                  yytext = 'WF'; return 'COUNTRY'
"Yémen"                             yytext = 'YE'; return 'COUNTRY'
"le Yémen"                          yytext = 'YE'; return 'COUNTRY'
"Zambie"                            yytext = 'ZM'; return 'COUNTRY'
"la Zambie"                         yytext = 'ZM'; return 'COUNTRY'
"Zimbabwe"                          yytext = 'ZW'; return 'COUNTRY'
"le Zimbabwe"                       yytext = 'ZW'; return 'COUNTRY'



/* Not-a-country
   "Pays de Galles"                  yytext = 'at'; return 'COUNTRY'
  "Baléares"                          yytext = ''; return 'COUNTRY'
  "Irlande du Nord"                   yytext = ''; return 'COUNTRY'
  "Écosse"                            yytext = ''; return 'COUNTRY'
*/

"et le"     /* skip */
"et la"     /* skip */
"et l'"     /* skip */
"et les"    /* skip */

{INTEGER}    return 'INTEGER'
{FLOAT}      return 'FLOAT'
{NAME}       return 'NAME'

\s+          /* skip whitespace */
<<EOF>>     return 'EOF'
[,]         /* skip */
.           return yytext

/lex

/* operator association and precedence, if any */

%% /* grammar */

start
  : hide_emergency fr_cgu EOF { return async function () { if (await $1(this)) return; await $2(this); } }
  ;

hide_emergency
  : REGULATORY fr_cgu_sentence -> $2
  ;

fr_cgu /* For now we execute all sentences in the order they are presented (except for the first sentence, about emergency calls,
          see above). This probably should be modified to include more generic "return"-like code. */
  : fr_cgu fr_cgu_sentence -> async function (ctx) { await $1(ctx); await $2(ctx) }
  | fr_cgu_sentence -> $1
  ;

fr_cgu_sentence
  : sentence '.' -> async function (ctx) { await yy.op.reset_up_to.call(ctx); return await $1(ctx); }
  ;

sentence /* return true if terminated */
  : CALLS conditions outcomes             -> async function (ctx) { var cond = await $2(ctx);                      if (cond) { await $3(ctx) }; return cond }
  | CALLS outcomes conditions             -> async function (ctx) { var cond = await $3(ctx);                      if (cond) { await $2(ctx) }; return cond }
  | CALLS conditions outcomes conditions  -> async function (ctx) { var cond = (await $2(ctx)) && (await $4(ctx)); if (cond) { await $3(ctx) }; return cond }
  ;

conditions
  : conditions condition -> async function (ctx) { return (await $1(ctx)) && (await $2(ctx)) }
  | condition -> $1
  ;

outcomes
  : outcomes outcome     -> async function (ctx) { await $1(ctx); await $2(ctx) }
  | outcome -> $1
  ;

condition
  : CALLED_ONNET              -> function (ctx) { return yy.op.called_onnet.call(ctx) }
  | CALLED_ONNET names        -> function (ctx) { return yy.op.called_onnet.call(ctx) } /* "sur le réseau K-net" */
  | CALLED_FIXED              -> function (ctx) { return yy.op.called_fixed.call(ctx) }
  | CALLED_FIXED_OR_MOBILE    -> function (ctx) { return yy.op.called_fixed_or_mobile.call(ctx) }
  | CALLED_MOBILE             -> function (ctx) { return yy.op.called_mobile.call(ctx) }
  | EMERGENCY                 -> function (ctx) { return yy.op.called_emergency.call(ctx) }
  | TOWARDS countries         -> function (ctx) { return yy.op.called_country.call(ctx,$2) }
  | ATMOST duration PER_CALL  -> function (ctx) { return yy.op.per_call_up_to.call(ctx,$2) }
  /* Notice how the names are computed at compilation time, not at evaluation time. */
  | ATMOST callees                  { var name = 'C'+yy.new_name(); $$ = async function (ctx) { await yy.op.count_called.call(ctx,name);          return await yy.op.at_most.call(ctx,$2,name) }}
  | ATMOST callees names            { var name = 'C'+$3;            $$ = async function (ctx) { await yy.op.count_called.call(ctx,name);          return await yy.op.at_most.call(ctx,$2,name) }}
  | ATMOST callees names PER_CYCLE  { var name = 'C'+$3;            $$ = async function (ctx) { await yy.op.count_called.call(ctx,name);          return await yy.op.at_most.call(ctx,$2,name) }}
  | ATMOST callees period           { var name = 'C'+yy.new_name(); $$ = async function (ctx) { await yy.op.count_called.call(ctx,name,$3);       return await yy.op.at_most.call(ctx,$2,name) }}
  | ATMOST callees names period     { var name = 'C'+$3;            $$ = async function (ctx) { await yy.op.count_called.call(ctx,name,$4);       return await yy.op.at_most.call(ctx,$2,name,$4) }}
  | ATMOST duration PER_CYCLE       { var name = 'D'+yy.new_name(); $$ = async function (ctx) { await yy.op.increment_duration.call(ctx,name);    return await yy.op.up_to.call(ctx,$2,name) }}
  | ATMOST duration names PER_CYCLE { var name = 'D'+$3;            $$ = async function (ctx) { await yy.op.increment_duration.call(ctx,name);    return await yy.op.up_to.call(ctx,$2,name) }}
  | ATMOST duration names period    { var name = 'D'+$3;            $$ = async function (ctx) { await yy.op.increment_duration.call(ctx,name,$4); return await yy.op.up_to.call(ctx,$2,name,$4) }}
  ;

callees
  : integer CALLEE -> $1
  ;

duration
  : integer time_unit -> $1 * $2
  ;

period
  : PER_DAY       -> 'day'
  | PER_HOUR      -> 'hour'
  | PER_WEEK      -> 'week'
  | DAY_OF_WEEK   -> 'day-of-week'
  ;

time_unit
  : SECONDS -> 1
  | MINUTES -> 60
  | HOURS   -> 3600
  ;

countries
  : countries country -> $1.concat([$2])
  | country           -> [$1]
  ;

country
  : COUNTRY -> yytext.toLowerCase()
  ;

outcome
  : FREE      -> async function (ctx) { await yy.op.free.call(ctx) }
  | HIDE_CALL -> async function (ctx) { await yy.op.hide_call.call(ctx) }
  ;

/* Constants */

names
  : names name    -> $1+' '+$2
  | names string  -> $1+' '+$2
  | name          -> $1
  | string        -> $1
  ;

integer
  : INTEGER   -> parseInt(yytext,10)
  ;

float
  : FLOAT     -> parseFloat(yytext.replace(',','.'))
  ;

string
  : STRING    -> yytext.substr(1,yytext.length-2)
  ;

pattern
  : PATTERN   -> yytext.substr(1,yytext.length-2)
  ;

name
  : NAME      -> yytext
  ;
