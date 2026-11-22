/* Contenu commun des directions sombres C et D.
   TOUS les textes viennent de l'appli actuelle (captures « avant » de la démo et code
   des écrans). Rien d'ajouté, rien de retiré, même ordre. Seul le visuel (CSS) change. */
const ICON = {
  trophy:'<svg viewBox="0 0 24 24"><path d="M7 4h10v5a5 5 0 0 1-10 0V4Zm0 2H4v2a3 3 0 0 0 3 3M17 6h3v2a3 3 0 0 1-3 3M12 14v4m-4 2h8"/></svg>',
  bell:'<svg viewBox="0 0 24 24"><path d="M6 17V11a6 6 0 0 1 12 0v6l2 2H4l2-2Zm4 3a2 2 0 0 0 4 0"/></svg>',
  gear:'<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M18.4 5.6l-2.1 2.1M7.7 16.3l-2.1 2.1"/></svg>',
  cal:'<svg viewBox="0 0 24 24"><rect x="4" y="5" width="16" height="15" rx="2"/><path d="M4 10h16M9 3v4M15 3v4"/></svg>',
  bars:'<svg viewBox="0 0 24 24"><path d="M6 20V12m6 8V5m6 15v-9"/></svg>',
  back:'<svg viewBox="0 0 24 24"><path d="M19 12H5m6-6-6 6 6 6"/></svg>',
  plus:'<svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg>',
  check:'<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8"/><path d="m8.5 12 2.5 2.5 4.5-5"/></svg>',
  cross:'<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8"/><path d="m9 9 6 6m0-6-6 6"/></svg>',
  chev:'<svg viewBox="0 0 24 24"><path d="m6 9 6 6 6-6"/></svg>',
  ball:'<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8"/><path d="m12 8 3 2-1 3.5h-4L9 10l3-2Z"/></svg>',
  crown:'<svg viewBox="0 0 24 24"><path d="m4 17 1-9 4 4 3-6 3 6 4-4 1 9Z"/></svg>'
};
const crest='<span class="crest"><svg viewBox="0 0 24 28"><path d="M12 1 2 4v10c0 6 4 10 10 13 6-3 10-7 10-13V4L12 1Z"/><circle cx="12" cy="13" r="4"/></svg></span>';
const ME='FC Démo';
function team(name,own){return `<div class="team ${own?'own':''}">${own?crest:''}<span class="tn">${name}</span></div>`}
function mc({head,home,away,score,foot,actions,cls='',own='home',res=''}){
  const mid=score?`<div class="mid score ${res}">${score}</div>`:'<div class="mid vs">VS</div>';
  return `<article class="mc ${cls}"><div class="mc-head">${head}</div><div class="mc-body">${team(home,own==='home')}${mid}${team(away,own==='away')}</div>${foot?`<div class="mc-foot">${foot}</div>`:''}${actions||''}</article>`;
}
const NAV=[['accueil.html','Calendrier','cal'],['stats.html','Statistiques','bars']];
function shell(active,title,inner,opts={}){
  const links=NAV.map(([h,l,i])=>`<a class="${h===active?'on':''}" href="${h}"><span class="ic">${ICON[i]}</span><span>${l}</span></a>`).join('');
  const bar=opts.back?`<header class="bar detail"><a class="ic back" href="accueil.html">${ICON.back}</a>${inner.head}</header>`
   :`<header class="bar">${crest}<h1>${title}</h1><div class="acts"><span class="ic">${ICON.trophy}</span><span class="ic">${ICON.bell}</span><span class="ic">${ICON.gear}</span></div></header>`;
  document.body.innerHTML=`<div class="app"><nav class="side"><div class="logo">${crest}</div>${links}</nav><div class="col">${bar}<main>${opts.back?inner.body:inner}</main></div></div><nav class="tabbar">${links}</nav>`;
}
const SCREENS={
accueil(){
 const act=`<div class="actions"><span class="btn yes"><span class="ic">${ICON.check}</span>Présent</span><span class="btn"><span class="ic">${ICON.cross}</span>Absent</span></div>`;
 shell('accueil.html','Calendrier',`
 <div class="cta"><span class="btn new"><span class="ic">${ICON.plus}</span>Nouvel événement</span></div>
 <section class="sec"><h2>Terminés</h2>
  ${mc({head:'Mercredi 04 Novembre 2026 • 14:00 • Championnat · J7',home:'US Les Peupliers',away:ME,score:'2 – 4',own:'away',res:'win',cls:'done win'})}
  ${mc({head:'Mercredi 11 Novembre 2026 • 14:00 • Championnat · J8',home:ME,away:'AS Val Fleuri',score:'2 – 0',res:'win',cls:'done win'})}
 </section>
 <section class="sec"><h2>À venir</h2>
  ${mc({head:'Samedi 21 Novembre 2026 • 14:00',home:ME,away:'FC Rive Gauche',foot:'Championnat · J9',cls:'up'})}
  ${mc({head:'Dimanche 22 Novembre 2026 • 20:00 • Championnat · J10',home:ME,away:'ES Trois Chênes',actions:act,cls:'up next'})}
 </section>`);
},
match(){
 const head=mc({head:'Dimanche 22 Novembre 2026 • 20:00 • Championnat · J10',home:ME,away:'ES Trois Chênes',cls:'up next top'});
 const body=`<nav class="subtabs"><a class="on">Info</a><a>Effectif</a><a>Compo</a><a>Prono</a></nav>
 <section class="panel info"><p class="rdv">Rendez-vous  19h30</p><h3>Dernière rencontre</h3><p class="quiet">Aucune rencontre passée contre cet adversaire.</p></section>`;
 shell('accueil.html','',{head,body},{back:true});
},
compo(){
 const head=mc({head:'Mercredi 11 Novembre 2026 • 14:00 • Championnat · J8',home:ME,away:'AS Val Fleuri',score:'2 – 0',res:'win',cls:'done win top'});
 // placement visuel en 4-2-3-1 (x,y en %) ; noms, ballon et couronne identiques à l'appli
 const P=[['Yanis',50,12,''],['Théo',17,30,'ball'],['Maxime',50,32,'crown'],['Mehdi',83,30,''],['Antoine',34,52,''],['Sofiane',66,52,''],['Romain',12,72,''],['Kevin',37,76,'ball'],['Baptiste',63,76,''],['Nathan',88,72,''],['Alexis',50,92,'']];
 const side=['Alexis','Florian','Quentin'];
 const ini=n=>n.slice(0,2).toUpperCase();
 const pl=([n,x,y,k])=>`<div class="pl ${k}" style="left:${x}%;top:${y}%"><span class="tile">${ini(n)}</span>${k==='crown'?`<span class="mk">${ICON.crown}</span>`:''}${k==='ball'?`<span class="mk">${ICON.ball}</span>`:''}<span class="nm">${n}</span></div>`;
 // Alexis est sur le côté dans l'appli : on le retire du terrain
 const field=P.filter(p=>p[0]!=='Alexis');
 const body=`<div class="lineup"><div class="benchcol">${side.map(n=>`<div class="pl bench"><span class="tile">${ini(n)}</span><span class="nm">${n}</span></div>`).join('')}</div><div class="pitch"><i class="l ml"></i><i class="l circ"></i><i class="l box top"></i><i class="l box bot"></i>${field.map(pl).join('')}</div></div>
 <div class="fold"><span>Votes de l’Homme du match</span><span class="ic">${ICON.chev}</span></div><div class="fold"><span>Prono</span><span class="ic">${ICON.chev}</span></div>`;
 shell('accueil.html','',{head,body},{back:true});
},
stats(){
 const R=[['Yanis',7,3,0,2,2,4,2,1],['Antoine',7,1,0,2,0,5,2,0],['Maxime',7,1,0,2,2,4,2,1],['Mehdi',7,1,0,2,1,5,2,0],['Alexis',7,0,0,2,0,4,2,1],['Florian',7,0,0,2,0,5,2,0],['Lucas',7,0,0,2,1,5,2,0],['Julien',6,2,0,1,1,3,2,1],['Kevin',6,2,0,1,1,4,1,1],['Baptiste',6,1,0,1,0,4,1,1]];
 shell('stats.html','Statistiques',`
 <nav class="subtabs"><a class="on">Joueurs</a><a>Équipe</a><a>Prono</a></nav>
 <nav class="period"><a class="on">Actuelle</a><a>Précédente</a><a>Toutes</a></nav>
 <div class="panel"><table class="tbl"><thead><tr><th></th><th>J</th><th>B</th><th>PD</th><th>CS</th><th>HDM</th><th>G</th><th>N</th><th>P</th></tr></thead><tbody>
 ${R.map((r,i)=>`<tr><td><span class="rk">${i+1}</span>${r[0]}</td>${r.slice(1).map(v=>`<td>${v}</td>`).join('')}</tr>`).join('')}
 </tbody></table></div>`);
}};
