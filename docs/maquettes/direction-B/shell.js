const NAV=[["accueil.html","Accueil"],["match.html","Match"],["compo.html","Composition"],["stats.html","Stats"]];
function shell(active,title,inner){
  const links=NAV.map(([h,l])=>`<a class="${h===active?'on':''}" href="${h}">${l}</a>`).join('');
  document.body.innerHTML=`<div class="app"><nav class="side stripes"><div class="logo">PETIT FILET</div>${links}</nav>
  <div><header class="hero stripes"><span class="brand">FC Démo · saison 2026-27</span><h1>${title}</h1></header><main>${inner}</main></div></div>
  <nav class="tabbar">${links}</nav>`;
}
