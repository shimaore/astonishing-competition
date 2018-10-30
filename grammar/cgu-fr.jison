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
"Allemagne"                         yytext = 'de'; return 'COUNTRY'
"Argentine"                         yytext = 'ar'; return 'COUNTRY'
"Australie"                         yytext = 'au'; return 'COUNTRY'
"Autriche"                          yytext = 'at'; return 'COUNTRY'
"Belgique"                          yytext = 'be'; return 'COUNTRY'
"Brésil"                            yytext = 'br'; return 'COUNTRY'
"Canada"                            yytext = 'ca'; return 'COUNTRY'
"Chili"                             yytext = 'cl'; return 'COUNTRY'
"Chine"                             yytext = 'cn'; return 'COUNTRY'
"Chypre"                            yytext = 'cy'; return 'COUNTRY'
"Colombie"                          yytext = 'co'; return 'COUNTRY'
"Danemark"                          yytext = 'dk'; return 'COUNTRY'
"Espagne"                           yytext = 'es'; return 'COUNTRY'
"Estonie"                           yytext = 'ee'; return 'COUNTRY'
"France métropolitaine"             yytext = 'fr'; return 'COUNTRY'
"Grèce"                             yytext = 'gr'; return 'COUNTRY'
"Guam"                              yytext = 'gu'; return 'COUNTRY'
"Hong-Kong"                         yytext = 'hk'; return 'COUNTRY'
"Hongrie"                           yytext = 'hu'; return 'COUNTRY'
"Iles Vierges (U.S.)"               yytext = 'vi'; return 'COUNTRY'
"Irlande"                           yytext = 'ie'; return 'COUNTRY'
"Islande"                           yytext = 'is'; return 'COUNTRY'
"Israël"                            yytext = 'il'; return 'COUNTRY'
"Italie"                            yytext = 'it'; return 'COUNTRY'
"Kazakhstan"                        yytext = 'kz'; return 'COUNTRY'
"Lettonie"                          yytext = 'lv'; return 'COUNTRY'
"Luxembourg"                        yytext = 'lu'; return 'COUNTRY'
"Malaisie"                          yytext = 'my'; return 'COUNTRY'
"Mexique"                           yytext = 'mx'; return 'COUNTRY'
"Norvège"                           yytext = 'no'; return 'COUNTRY'
"Nouvelle Zélande"                  yytext = 'nz'; return 'COUNTRY'
"Panama"                            yytext = 'pa'; return 'COUNTRY'
"Pays Bas"                          yytext = 'nl'; return 'COUNTRY'
"Pologne"                           yytext = 'pl'; return 'COUNTRY'
"Portugal"                          yytext = 'pt'; return 'COUNTRY'
"Pérou"                             yytext = 'pe'; return 'COUNTRY'
"Royaume-Uni"                       yytext = 'uk'; return 'COUNTRY'
"Russie"                            yytext = 'ru'; return 'COUNTRY'
"Singapour"                         yytext = 'sg'; return 'COUNTRY'
"Slovaquie"                         yytext = 'sk'; return 'COUNTRY'
"Suisse"                            yytext = 'ch'; return 'COUNTRY'
"Suède"                             yytext = 'se'; return 'COUNTRY'
"Taïwan"                            yytext = 'tw'; return 'COUNTRY'
"Thaïlande"                         yytext = 'th'; return 'COUNTRY'
"USA"                               yytext = 'us'; return 'COUNTRY'
"Vatican"                           yytext = 'va'; return 'COUNTRY'
"Venezuela"                         yytext = 've'; return 'COUNTRY'
"Vénézuéla"                         yytext = 've'; return 'COUNTRY'
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
  : COUNTRY -> yytext
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
