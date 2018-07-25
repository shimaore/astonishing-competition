/* Parses flat-ornament text syntax */

%lex

FLOAT       [0-9]+"."(?:[0-9]+)?\b
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

"Conditions Générales d'Utilisation"        return 'CGU'
"Conformément à la réglementation, les appels d'urgences ne sont pas facturés."   return 'EMERGENCY'

"Les appels"                         return 'CALLS'
"sur le réseau"                      return 'CALLED_ONNET'
"vers les fixes"                     return 'CALLED_FIXED'
"vers les mobiles"                   return 'CALLED_MOBILE'
"vers les fixes et les mobiles"      return 'CALLED_FIXED_OR_MOBILE'
"vers"                               return 'TOWARDS'
"en"                                 return 'TOWARDS'
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
"sont gratuits"                      return 'FREE'
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

"France métropolitaine"              yytext = 'fr'; return 'COUNTRY'
"Allemagne"                          yytext = 'de'; return 'COUNTRY'
"Royaume-Uni"                        yytext = 'uk'; return 'COUNTRY'
"Argentine"                          return 'COUNTRY'
"Australie"                          return 'COUNTRY'
"Autriche" return 'xx'
"Baléares" return 'xx'
"Belgique"                           yytext = 'be'; return 'COUNTRY'
"Brésil" return 'xx'
"Canada" return 'xx'
"Chili" return 'xx'
"Chine" return 'xx'
"Chypre" return 'xx'
"Colombie" return 'xx'
"Danemark" return 'xx'
"Écosse" return 'xx'
"Espagne" return 'xx'
"Estonie" return 'xx'
"France métropolitaine" return 'xx'
"Grèce" return 'xx'
"Guam" return 'xx'
"Hong-Kong" return 'xx'
"Hongrie" return 'xx'
"Iles Vierges (U.S.)" return 'xx'
"Islande" return 'xx'
"Irlande" return 'xx'
"Irlande du Nord" return 'xx'
"Israël" return 'xx'
"Italie" return 'xx'
"Kazakhstan" return 'xx'
"Lettonie" return 'xx'
"Luxembourg" return 'xx'
"Malaisie" return 'xx'
"Mexique" return 'xx'
"Norvège" return 'xx'
"Nouvelle Zélande" return 'xx'
"Panama" return 'xx'
"Pays Bas" return 'xx'
"Pays de Galles" return 'xx'
"Pologne" return 'xx'
"Portugal" return 'xx'
"Pérou" return 'xx'
"Russie" return 'xx'
"Singapour" return 'xx'
"Slovaquie" return 'xx'
"Suisse"                               yytext = 'ch'; return 'COUNTRY'
"Suède" return 'xx'
"Taïwan" return 'xx'
"Thaïlande" return 'xx'
"USA"                    return 'us'
"Vatican" return 'xx'

[,]          /* ignore */
{INTEGER}    return 'INTEGER'
{NAME}       return 'NAME'

\s+          /* skip whitespace */
<<EOF>>     return 'EOF'
.           return yytext

/lex

/* operator association and precedence, if any */

%% /* grammar */

start
  : CGU hide_emergency fr_cgu EOF -> async function () { if ($2()) return; await $3(); }
  ;

hide_emergency
  : EMERGENCY -> async function () { var emergency = yy.valid_op.called_emergency(); if (emergency) { yy.valid_op.hide_call() } return emergency; }
  ;

fr_cgu
  : fr_cgu fr_cgu_sentence -> async function () { var cond = await $1(); if (!cond) return; return await $2() }
  | fr_cgu_sentence -> $1
  ;

fr_cgu_sentence
  : sentence '.' -> async function () { await yy.op.reset_up_to(); return await $1() }
  ;

sentence
  : CALLS conditions outcomes             -> async function () { var cond = await $2(); if (cond) { await $3() }; }
  | CALLS conditions outcomes conditions  -> async function () { var cond = (await $2()) && (await $4()); if (cond) { await $4 }; }
  | CALLS outcomes conditions             -> async function () { var cond =  await $3(); if (cond) { await $2() }; }
  ;

conditions
  : conditions condition -> $1.concat($2)
  | condition -> [$1]
  ;

outcomes
  : outcomes outcome -> $1.concat($2)
  | outcome -> [$1]
  ;

condition
  : CALLED_ONNET            -> yy.op.called_onnet
  | CALLED_ONNET NAME       -> yy.op.called_onnet /* "sur le réseau K-net" */
  | CALLED_FIXED            -> yy.op.called_fixed
  | CALLED_FIXED_OR_MOBILE  -> yy.op.called_fixed_or_mobile
  | CALLED_MOBILE           -> yy.op.called_mobile
  | TOWARDS countries       -> function () { return yy.op.called_country($2) }
  | ATMOST callees          { var name = yy.new_name(); $$ = async function () { await yy.op.count_called(name); return await yy.op.at_most($2,name) }}
  | ATMOST callees name     { var name = 'callee_'+$3;  $$ = async function () { await yy.op.count_called(name); return await yy.op.at_most($2,name) }}
  | ATMOST callees name PER_CYCLE  { var name = 'callee_'+$3;  $$ = async function () { await yy.op.count_called(name); return await yy.op.at_most($2,name) }}
  | ATMOST callees period   { var name = yy.new_name(); $$ = async function () { await yy.op.count_called_per(name,$3); return await yy.op.at_most($2,name) }}
  | ATMOST callees name period     { var name = 'callee_'+$3;  $$ = async function () { await yy.op.count_called_per(name,$4); return await yy.op.at_most_per($2,name,$4) }}
  | ATMOST duration PER_CALL       {                           $$ = async function () { await yy.op.per_call_up_to($2) }}
  | ATMOST duration PER_CYCLE      { var name = yy.new_name(); $$ = async function () { await yy.op.increment_duration(name); return await yy.op.up_to($2,name) }}
  | ATMOST duration name PER_CYCLE -> name = $3;            $$ = [{type:'increment_duration',param:name},{type:'up_to',params:[$2,name]}]
  | ATMOST duration name period    -> name = $3;            $$ = [{type:'increment_duration_per',params:[name,$4]},{type:'up_to_per',params:[$2,name,$4]}]
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
  : countries ',' country -> $1.concat([$3])
  | country               -> [$1]
  ;

country
  : COUNTRY -> yytext
  ;

outcome
  : FREE -> [{type:'free'}]
  ;

/* Constants */

integer
  : INTEGER   -> parseInt(yytext,10)
  ;

float
  : FLOAT     -> parseFloat(yytext)
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
