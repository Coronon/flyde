(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[405],{4285:function(e,n,r){"use strict";r.r(n),r.d(n,{default:function(){return z}});var t=r(5893),a=r(809),o=r.n(a),c=r(2447),s=r(7294),i=r(911),u=r.n(i),l=r(6265);function f(e,n,r){n/=100,r/=100;var t=function(n){return(n+e/60)%6},a=function(e){return r*(1-n*Math.max(0,Math.min(t(e),4-t(e),1)))};return[255*a(5),255*a(3),255*a(1)]}var d=r(8826),p=r.n(d);function h(e,n){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var t=Object.getOwnPropertySymbols(e);n&&(t=t.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),r.push.apply(r,t)}return r}function v(e,n){var r=arguments.length>2&&void 0!==arguments[2]?arguments[2]:0,t=arguments.length>3&&void 0!==arguments[3]?arguments[3]:130,a=(t-r)*e+r;return f(a,100,n).map((function(e){return Math.ceil(e).toString(16).padStart(2,"0")})).join("").padStart(7,"#")}function m(e){var n=function(e){for(var n=1;n<arguments.length;n++){var r=null!=arguments[n]?arguments[n]:{};n%2?h(Object(r),!0).forEach((function(n){(0,l.Z)(e,n,r[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):h(Object(r)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(r,n))}))}return e}({},e).value,r=(0,s.useRef)(null),a=(0,s.useRef)(null);return(0,s.useEffect)((function(){if(r.current&&a.current){var e=r.current,t=a.current,o=2*e.r.baseVal.value*Math.PI,c=o-(null!==n&&void 0!==n?n:1)*o;e.style.strokeDasharray="".concat(o," ").concat(o),e.style.strokeDashoffset="".concat(o),e.style.strokeDashoffset="".concat(c),e.style.stroke=n?v(n,78):"#C4C4C4",t.textContent=n?"".concat((100*n).toFixed(0),"%"):"N/A",t.style.fill=n?v(n,28):"#C4C4C4"}}),[n]),(0,t.jsx)("div",{className:p().container,children:(0,t.jsxs)("svg",{width:"100%",height:"100%",viewBox:"0 0 100 100",className:p().draw,children:[(0,t.jsx)("circle",{ref:r,className:p().circle,stroke:"transparent",strokeWidth:"".concat(10,"%"),fill:"transparent",r:"".concat(44,"%"),cx:"50%",cy:"50%",strokeLinecap:"round"}),(0,t.jsx)("text",{ref:a,className:p().label,textAnchor:"middle",fontSize:"100%",x:"52%",y:"52%"})]})})}function b(e){var n,r,a=(0,s.useRef)(null),o=function(e){e.preventDefault(),a.current&&a.current.classList.add(u().clicked)},c=function(e){e.preventDefault(),a.current&&a.current.classList.remove(u().clicked)},i=function(n){c(n),e.coverage&&window.open("https://coronon.github.io/flyde/".concat(e.branchName),"__blank")};return(0,t.jsx)("div",{ref:a,className:u().container,onMouseDown:o,onMouseUp:i,onMouseLeave:c,onTouchStart:o,onTouchEnd:i,children:(0,t.jsxs)("div",{className:u().vSpace,children:[(0,t.jsxs)("div",{style:{paddingRight:"3rem"},children:[(0,t.jsx)("span",{className:u().primary,style:{paddingBottom:"1.4rem"},children:e.branchName}),(0,t.jsxs)("div",{className:u().secondary,children:[(0,t.jsxs)("div",{className:u().vSpace,children:[(0,t.jsx)("span",{className:u().label,children:"Last Access:"}),(0,t.jsx)("span",{children:null!==(n=null===(r=e.access)||void 0===r?void 0:r.toLocaleDateString())&&void 0!==n?n:"-- / --"})]}),(0,t.jsxs)("div",{className:u().vSpace,children:[(0,t.jsx)("span",{className:u().label,children:"Sha:"}),(0,t.jsx)("span",{children:e.sha})]})]})]}),(0,t.jsx)("div",{style:{width:"min(30vw, 150px)",height:"min(30vw, 150px)"},children:(0,t.jsx)(m,{value:e.coverage})})]})})}var y=r(9830),_=r.n(y);function x(e){var n=(0,s.useRef)(null);return(0,t.jsx)("div",{className:_().container,style:{visibility:e.shown?"visible":"hidden"},children:(0,t.jsxs)("div",{className:_().body,children:[(0,t.jsxs)("div",{className:_().closeButton,onClick:e.onClose,children:[(0,t.jsx)("span",{}),(0,t.jsx)("span",{})]}),(0,t.jsx)("h2",{className:_().label,children:"Please Enter Your GitHub Access Token"}),(0,t.jsx)("input",{className:_().input,ref:n,type:"text",autoComplete:"off",autoCapitalize:"off",autoCorrect:"off"}),(0,t.jsx)("button",{className:_().button,onClick:function(){var r,t;n.current&&(null===(t=e.onReceiveToken)||void 0===t||t.call(null,n.current.value));null===(r=e.onClose)||void 0===r||r.call(null)},children:"Done"})]})})}var g=r(1385),w=r(4047),j=r(2700),k=r(886),C=r(8764).Buffer;function N(e,n){var r;if("undefined"===typeof Symbol||null==e[Symbol.iterator]){if(Array.isArray(e)||(r=function(e,n){if(!e)return;if("string"===typeof e)return P(e,n);var r=Object.prototype.toString.call(e).slice(8,-1);"Object"===r&&e.constructor&&(r=e.constructor.name);if("Map"===r||"Set"===r)return Array.from(e);if("Arguments"===r||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(r))return P(e,n)}(e))||n&&e&&"number"===typeof e.length){r&&(e=r);var t=0,a=function(){};return{s:a,n:function(){return t>=e.length?{done:!0}:{done:!1,value:e[t++]}},e:function(e){throw e},f:a}}throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}var o,c=!0,s=!1;return{s:function(){r=e[Symbol.iterator]()},n:function(){var e=r.next();return c=e.done,e},e:function(e){s=!0,o=e},f:function(){try{c||null==r.return||r.return()}finally{if(s)throw o}}}}function P(e,n){(null==n||n>e.length)&&(n=e.length);for(var r=0,t=new Array(n);r<n;r++)t[r]=e[r];return t}var S=function(){function e(){(0,w.Z)(this,e)}return(0,j.Z)(e,null,[{key:"persist",value:function(){this.branches&&localStorage.setItem(e.storageKey,JSON.stringify(Array.from(this.branches.entries())))}},{key:"load",value:function(){if(void 0==this.branches){var n=localStorage.getItem(e.storageKey);this.branches=null!==n?new Map(JSON.parse(n,(function(e,n){return"date"===e?new Date(n):n}))):new Map}}},{key:"updateCache",value:function(e){if(this.branches){var n,r=N(e);try{for(r.s();!(n=r.n()).done;){var t=n.value;this.branches.set(t.name,t)}}catch(a){r.e(a)}finally{r.f()}}}},{key:"getCache",value:function(){return this.branches?(0,g.Z)(this.branches.values()):[]}},{key:"needsRecompute",value:function(e){var n=this;if(void 0===this.branches)return[];var r,t=[],a=N(e);try{var o=function(){var e=r.value;n.branches.has(e.name)&&!function(){var r;return(null===(r=n.branches.get(e.name))||void 0===r?void 0:r.sha)!==e.sha}()||t.push(e)};for(a.s();!(r=a.n()).done;)o()}catch(u){a.e(u)}finally{a.f()}var c,s=N((0,g.Z)(this.branches.keys()).filter((function(n){return!e.find((function(e){return e.name===n}))})));try{for(s.s();!(c=s.n()).done;){var i=c.value;this.branches.delete(i)}}catch(u){s.e(u)}finally{s.f()}return t}}]),e}();function O(e){return T.apply(this,arguments)}function T(){return(T=(0,c.Z)(o().mark((function e(n){var r,t,a,s,i;return o().wrap((function(e){for(;;)switch(e.prev=e.next){case 0:return S.load(),r=n?k.W.defaults({headers:{authorization:"token ".concat(n)}}):k.W,t=function(){var e=(0,c.Z)(o().mark((function e(n){var t,a,c,s,i,u,l,f;return o().wrap((function(e){for(;;)switch(e.prev=e.next){case 0:return e.prev=0,e.next=3,r("GET /repos/{owner}/{repo}/contents/{path}",{owner:"Coronon",repo:"flyde",path:"".concat(n,"/index.html"),ref:"gh-pages"});case 3:if(c=e.sent,s=new DOMParser,i=c.data,u=i.content){e.next=8;break}throw new Error("Cannot get coverage HTML from response");case 8:if(l=s.parseFromString(C.from(u,"base64").toString(),"text/html"),!(f=null===(t=l.getElementsByClassName("headerCovTableEntryHi").item(0))||void 0===t||null===(a=t.innerHTML)||void 0===a?void 0:a.replace(" %",""))){e.next=12;break}return e.abrupt("return",parseFloat(f)/100);case 12:throw new Error("Cannot parse coverage value");case 15:return e.prev=15,e.t0=e.catch(0),console.error(e.t0),e.abrupt("return",null);case 19:case"end":return e.stop()}}),e,null,[[0,15]])})));return function(n){return e.apply(this,arguments)}}(),e.prev=3,e.next=6,r("GET /repos/{owner}/{repo}/branches",{owner:"Coronon",repo:"flyde"});case 6:return a=e.sent,s=S.needsRecompute(a.data.map((function(e){return{name:e.name,sha:e.commit.sha}}))),e.next=10,Promise.all(s.map(function(){var e=(0,c.Z)(o().mark((function e(n){var a,c,s,i,u;return o().wrap((function(e){for(;;)switch(e.prev=e.next){case 0:return e.next=2,r("GET /repos/{owner}/{repo}/commits/{ref}",{owner:"Coronon",repo:"flyde",ref:n.sha});case 2:return null!==(u=e.sent)&&void 0!==u&&null!==(a=u.data)&&void 0!==a&&null!==(c=a.commit)&&void 0!==c&&null!==(s=c.committer)&&void 0!==s&&s.date&&(n.date=new Date(u.data.commit.committer.date)),e.next=6,t(n.name);case 6:if(e.t1=i=e.sent,e.t0=null!==e.t1,!e.t0){e.next=10;break}e.t0=void 0!==i;case 10:if(!e.t0){e.next=14;break}e.t2=i,e.next=15;break;case 14:e.t2=void 0;case 15:return n.coverage=e.t2,e.abrupt("return",n);case 17:case"end":return e.stop()}}),e)})));return function(n){return e.apply(this,arguments)}}()));case 10:return i=e.sent,S.updateCache(i),S.persist(),e.abrupt("return",S.getCache());case 16:return e.prev=16,e.t0=e.catch(3),e.abrupt("return",null);case 19:case"end":return e.stop()}}),e,null,[[3,16]])})))).apply(this,arguments)}function E(e){return e.sort((function(e,n){return"master"===e.name?-1:"master"===n.name?1:"develop"===e.name?-1:"develop"===n.name?1:e.name.localeCompare(n.name)})),e}function D(e){return e.filter((function(e){return"gh-pages"!=e.name}))}(0,l.Z)(S,"branches",void 0),(0,l.Z)(S,"storageKey","branches");var I=r(5323),A=r.n(I),M=r(7281),Z=r.n(M);function R(){return(0,t.jsxs)("div",{className:Z().loading,children:[(0,t.jsx)("div",{}),(0,t.jsx)("div",{}),(0,t.jsx)("div",{})]})}var L=r(9008);function B(){return(B=(0,c.Z)(o().mark((function e(n){var r;return o().wrap((function(e){for(;;)switch(e.prev=e.next){case 0:if(new RegExp("^ghp_[0-9a-zA-Z]{36}$").test(n)){e.next=2;break}return e.abrupt("return",!1);case 2:return r=k.W.defaults({headers:{authorization:"token ".concat(n)}}),e.prev=3,e.next=6,r("GET /user");case 6:return e.abrupt("return",!0);case 9:return e.prev=9,e.t0=e.catch(3),e.abrupt("return",!1);case 12:case"end":return e.stop()}}),e,null,[[3,9]])})))).apply(this,arguments)}function z(){var e=(0,s.useState)(null),n=e[0],r=e[1],a=(0,s.useState)(!1),i=a[0],u=a[1],l=(0,s.useState)(null),f=l[0],d=l[1],p=function(){var e=(0,c.Z)(o().mark((function e(n){var t;return o().wrap((function(e){for(;;)switch(e.prev=e.next){case 0:return e.next=2,O(n);case 2:t=e.sent,r(E(D(null!==t&&void 0!==t?t:[])));case 4:case"end":return e.stop()}}),e)})));return function(n){return e.apply(this,arguments)}}();return(0,s.useEffect)((function(){var e=localStorage.getItem("ghp");d(e),null===e&&u(!0)}),[]),(0,s.useEffect)((function(){p(null!==f&&void 0!==f?f:void 0)}),[f]),(0,t.jsxs)("main",{children:[(0,t.jsxs)(L.default,{children:[(0,t.jsx)("title",{children:"flyde - Coverage"}),(0,t.jsx)("meta",{name:"viewport",content:"initial-scale=1.0, width=device-width"})]}),(0,t.jsx)("h1",{className:A().title,children:"Code Coverage - flyde"}),(0,t.jsx)("section",{className:A().grid,children:n?n.map((function(e){return(0,t.jsx)(b,{branchName:e.name,sha:e.sha.substring(0,7),access:e.date,coverage:e.coverage},e.name)})):(0,t.jsx)(R,{})}),(0,t.jsx)(x,{shown:i,onClose:function(){return u(!1)},onReceiveToken:function(e){(function(e){return B.apply(this,arguments)})(e).then((function(n){n&&(console.log(e),localStorage.setItem("ghp",e),d(e))})).catch((function(e){return console.error(e)}))}})]})}},5301:function(e,n,r){(window.__NEXT_P=window.__NEXT_P||[]).push(["/",function(){return r(4285)}])},911:function(e){e.exports={container:"Card_container__1qc6G",clicked:"Card_clicked__qIAUq",vSpace:"Card_vSpace__2J3yt",primary:"Card_primary__3LtYG",secondary:"Card_secondary__2qUAO",label:"Card_label__2Pron"}},8826:function(e){e.exports={container:"CircularProgressIndicator_container__2XBPF",draw:"CircularProgressIndicator_draw__3Thpl",circle:"CircularProgressIndicator_circle__3cfzz",labelContainer:"CircularProgressIndicator_labelContainer__3aPtm",label:"CircularProgressIndicator_label__2X6Pz"}},7281:function(e){e.exports={loading:"Loading_loading__1kgVX",bounce:"Loading_bounce__3tZp7"}},9830:function(e){e.exports={container:"TokenPrompt_container__3N6M6",body:"TokenPrompt_body__R3PmC",label:"TokenPrompt_label__AQ64J",input:"TokenPrompt_input__2I7lI",button:"TokenPrompt_button__3euBd",clicked:"TokenPrompt_clicked__3aYTY",closeButton:"TokenPrompt_closeButton__3Ub8O"}},5323:function(e){e.exports={title:"Home_title__3DjR7",grid:"Home_grid__2Ei2F"}}},function(e){e.O(0,[204,774,888,179],(function(){return n=5301,e(e.s=n);var n}));var n=e.O();_N_E=n}]);