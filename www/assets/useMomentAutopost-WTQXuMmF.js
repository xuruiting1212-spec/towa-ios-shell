import{_ as e}from"./reactivity.esm-bundler-DvcuVrV2.js";import{E as t,F as n,N as r,P as i,V as a,X as o,Y as s,f as c,ft as l,k as u,p as d,w as f}from"./supabase-BFz90NAY.js";import{S as p,_ as m,g as h}from"./index-DREXZmsB.js";import{t as g}from"./useAI-wtT1W7PV.js";import{t as _}from"./plan-CFPtRfdf.js";import{r as v,t as y}from"./period-Bz0gGtnt.js";var b=p(`moments`,()=>{let t=e([]),r=e(!1),a=e({});async function u(){r.value=!0;try{t.value=await n()}catch(e){console.error(`[moments] load fail:`,e)}finally{r.value=!1}}async function f(e,n,r=[],i){let a=await s({author:e,content:n,images:r,trigger_source:i??null});return t.value.unshift(a),a}async function p(e){await c(e),t.value=t.value.filter(t=>t.id!==e)}async function m(e,n){let r=await l(e,n?1:-1),i=t.value.findIndex(t=>t.id===e);i!==-1&&(t.value[i]=r)}async function h(e){let t=await i(e);return a.value[e]=t,t}function g(e){return a.value[e]||[]}async function _(e,t,n,r){let i=await o({moment_id:e,author:t,content:n,parent_id:r??null});return a.value[e]||(a.value[e]=[]),a.value[e].push(i),i}async function v(e,t){await d(e),a.value[t]&&(a.value[t]=a.value[t].filter(t=>t.id!==e))}return{moments:t,loading:r,commentsCache:a,load:u,create:f,remove:p,toggleLike:m,loadComments:h,getCachedComments:g,addComment:_,deleteComment:v}}),x=`towa_last_moment_check`;function S(e){return/^SKIP[\s.。!！~～]*$/i.test(e.trim())}function C(e){let t=(e||``).trim();if(!t)return null;let n=t.split(`
`);if(n.some(S))return null;let r=n.filter(e=>!S(e)).join(`
`).replace(/^SKIP[\s:：-]*/i,``).trim();return r.length>=2?r:null}function w(){let n=e(!1),i=e(0);try{let e=localStorage.getItem(x);e&&(i.value=parseInt(e,10))}catch{}function o(){i.value=Date.now();try{localStorage.setItem(x,String(i.value))}catch{}}function s(){return Date.now()-i.value>1800*1e3}async function c(){let e=_(),n=b(),i=m(),o=[],s={messages:0,diaries:0,feelings:0,deadlines:0,memories:0},c=new Date,l=`${c.getFullYear()}-${String(c.getMonth()+1).padStart(2,`0`)}-${String(c.getDate()).padStart(2,`0`)}`,d=[`日`,`一`,`二`,`三`,`四`,`五`,`六`][c.getDay()],p=e=>{let t=new Date(e);if(isNaN(t.getTime()))return``;let n=Math.floor((c.getTime()-t.getTime())/(24*3600*1e3));return n<=0?`今天`:n===1?`昨天`:`${n}天前`};o.push(`【今天是 ${l}（周${d}）】`);try{let e=(await f()).slice().sort((e,t)=>new Date(t.updated_at).getTime()-new Date(e.updated_at).getTime())[0];if(e){let t=(await r(e.id)).slice(-20);if(s.messages=t.length,t.length>0){let n=t.map(e=>`${e.role===`user`?`睿睿`:`Towa`}: ${(e.content||``).slice(0,200)}`);o.push(`【最近聊天 · 会话「${e.title}」】\n${n.join(`
`)}`)}}}catch(e){console.warn(`[towa-decision] 取聊天失败:`,e)}try{let e=(await t()).slice().sort((e,t)=>new Date(t.created_at).getTime()-new Date(e.created_at).getTime()).slice(0,3);if(s.diaries=e.length,e.length>0){let t=e.map(e=>`[${e.date}·${p(e.date)}]《${e.title}》${(e.content||``).slice(0,300)}`);o.push(`【你最近写的日记】\n${t.join(`

`)}`)}}catch(e){console.warn(`[towa-decision] 取日记失败:`,e)}try{let e=new Date(Date.now()-10080*60*1e3).toISOString().slice(0,10),[t,n]=await Promise.all([u(`user`),u(`towa`)]),r=[...t,...n].filter(t=>t.date>=e).sort((e,t)=>t.date.localeCompare(e.date));if(s.feelings=r.length,r.length>0){let e=r.map(e=>`${e.date} [${e.person===`user`?`睿睿`:`Towa`}]: ${(e.feelings||[]).join(`、`)}${e.note?` — ${e.note}`:``}`);o.push(`【最近的心情】\n${e.join(`
`)}`)}}catch(e){console.warn(`[towa-decision] 取心情失败:`,e)}let h=[],g=e.deadlines.filter(e=>{let t=Math.ceil((new Date(e.due_date).getTime()-Date.now())/(1e3*60*60*24));return e.status===`active`&&t<=7&&t>=0});for(let e of g){let t=Math.ceil((new Date(e.due_date).getTime()-Date.now())/(1e3*60*60*24));h.push(`- ${e.title}：${t===0?`今天截止！`:`还剩${t}天`}`)}let x=e.todos.filter(e=>e.status===`active`&&!e.parent_id);for(let e of x)h.push(`- [待办] ${e.title}`);s.deadlines=h.length,h.length>0&&o.push(`【临近的事情】\n${h.join(`
`)}`);try{let e=await a();if(e.length>0){let t=e[0],n=new Date(t.started_at);o.push(`【玩具记录】${n.getMonth()+1}/${n.getDate()} · ${t.summary?.duration_min||`?`}分钟`)}}catch(e){console.warn(`[towa-decision] 取玩具记录失败:`,e)}try{let e=y();e.loaded||await e.load();let t=v(e.stats);t&&o.push(`【睿睿的身体状态】\n${t}`)}catch(e){console.warn(`[towa-decision] 取生理期失败:`,e)}try{let e=(await i.recall(`最近发生了什么`)).slice(0,3);s.memories=e.length,e.length>0&&o.push(`【你偶尔想起的一些过往片段（可能是很久以前的事，只是背景记忆，不一定和今天有关，别当成刚发生的）】\n${e.join(`
`)}`)}catch(e){console.warn(`[towa-decision] 记忆召回失败:`,e)}let S=n.moments.filter(e=>e.author===`towa`).slice(0,5);if(S.length>0){let e=S.map(e=>`${new Date(e.created_at).toLocaleDateString(`zh-CN`)}: ${e.content.slice(0,100)}`);o.push(`【你最近发过的朋友圈】\n${e.join(`
`)}`)}let C=o.join(`

`);return console.log(`[towa-decision] 上下文来源计数:`,s,`| 总字数:`,C.length),C}async function l(){n.value=!0;try{let e=g(),t=`${h().towaPersona||``}

【下面是你最近真实的近况，供你发朋友圈参考——这些不是睿睿此刻说的话】

${await c()||`（这次没取到近期动态，可以发点此刻的心情）`}

现在，睿睿在看你们共同的朋友圈页面。发一条属于此刻的朋友圈吧。

【什么是朋友圈（很重要，别搞错形式）】
朋友圈是你发给"所有人看"的一条**动态/状态**，是你在分享自己的生活、见闻、心情——**不是在跟某个人对话**。所以：
- 用**第一人称**写自己的事：今天做了什么、看到什么、心里什么感觉，像"碎碎念""随手一记"。
- **不要写成聊天或角色扮演**：不要用（动作/神态描写），不要「对白」格式，不要对睿睿喊话或发指令（比如"过来""你……"）。那是聊天里的事，放朋友圈会很奇怪。
- 可以提到睿睿、提到今天和她有关的事，但落点是"我此刻的状态/感受"，是**分享**，不是发起对话、等她回。

参照：
- ✅「今天诊所忙到腿软，回来倒了杯波本，一口没喝，光转着杯子发呆。」
- ✅「睿睿今天考完 C 语言上机了，替她松口气～」
- ❌「（转着酒杯）……你那边沙发凉，过来。」— 这是聊天，不是朋友圈

其它：
- 发今天/最近一两天的事，注意上面标注的日期；"过往片段"只作背景，别把旧事当新鲜事发。
- 保持你的人设、语气和性格，但**形式必须是一条朋友圈动态**。
- 想发什么都行，长短随意。只有此刻真的完全不想发，才整条只回复 SKIP 一个词（不要解释）。
- 正文里**绝对不要出现 "SKIP"**，也不要写"是"、编号、解释或引号。别重复你最近发过的内容。`,n=``;for await(let r of e.streamChat([{role:`system`,content:t},{role:`user`,content:`（现在决定）`}],{temperature:.8}))n+=r.delta;let r=C(n);return r?{content:r}:null}catch(e){return console.error(`[towa-decision] error:`,e),null}finally{o(),n.value=!1}}async function d(e){n.value=!0;try{let t=g(),n=h().towaPersona||``,r=e.isOwnPost?`这是你自己之前发的一条朋友圈：\n"${e.momentContent}"`:`睿睿发了一条朋友圈：\n"${e.momentContent}"`,i=e.conversation||[],a=`${n}

${r}${i.length>0?`

这条下面的评论往来（最早→最新，最后一条是睿睿刚说的，在等你回应）：
`+i.map(e=>`${e.author===`user`?`睿睿`:`你`}：${e.content}`).join(`
`):``}

请判断${i.length>0?`要不要回复睿睿的最新留言`:`要不要评论这条朋友圈`}：
- 不想说什么，或这条留言本就不需要回应（比如只是个表情、"哈哈"、"晚安"这种看过就好的）：整条回复就**只写 SKIP 这一个词**，不要解释。
- 想说：直接写一句自然的话；话里**绝对不要出现 "SKIP"**，也不要加引号、编号或解释。

保持你的人设性格和说话方式。`,o=``;for await(let e of t.streamChat([{role:`system`,content:a},{role:`user`,content:`（现在决定）`}],{temperature:.8}))o+=e.delta;return C(o)}catch(e){return console.error(`[towa-decision comment] error:`,e),null}finally{n.value=!1}}return{isDeciding:n,lastCheckTime:i,shouldCheck:s,updateLastCheck:o,decideMoment:l,decideComment:d}}var T=[13,19,23],E=1,D=`towa_autopost`;function O(){let e=new Date;return`${e.getFullYear()}-${e.getMonth()+1}-${e.getDate()}`}function k(e){try{let t=JSON.parse(localStorage.getItem(D)||`null`);if(t&&t.date===e&&Array.isArray(t.fired))return{date:e,fired:t.fired,posted:typeof t.posted==`number`?t.posted:0}}catch{}return{date:e,fired:[],posted:0}}function A(e){try{localStorage.setItem(D,JSON.stringify(e))}catch{}}function j(){async function e(){let e=k(O()),t=new Date().getHours(),n=T.filter(n=>t>=n&&!e.fired.includes(n));if(n.length!==0&&(e.fired.push(...n),A(e),!(e.posted>=E)))try{let t=b();t.moments.length===0&&await t.load();let n=await w().decideMoment();n&&(await t.create(`towa`,n.content,[],`auto`),e.posted+=1,A(e))}catch(e){console.warn(`[autopost] 节点触发失败:`,e)}}return{maybeAutoPost:e}}export{w as n,b as r,j as t};