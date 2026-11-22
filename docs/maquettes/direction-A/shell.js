// Gabarit commun des maquettes (menu + barre du bas), pour ne pas répéter le HTML.
const NAV=[["accueil.html","Accueil"],["match.html","Match"],["compo.html","Compo"],["stats.html","Stats"]];
function shell(active,title,inner){
  const links=(cls)=>NAV.map(([h,l])=>`<a class="${h===active?'on':''}" href="${h}">${l}</a>`).join('');
  document.body.innerHTML=`<div class="app"><nav class="side"><div class="logo">Petit Filet</div><span class="kicker">FC Démo</span>${links()}</nav>
  <main><header class="top"><h1>${title}</h1><span class="club">FC Démo · Saison 2026-27</span></header>${inner}</main></div>
  <nav class="tabbar">${links()}</nav>`;
}
