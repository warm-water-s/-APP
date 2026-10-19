/**
 * AI Outfit V1.0: executable behavioral contract, NOT Dart/Flutter compilation.
 *
 * Independent mirror of PRD's state invariants to provide machine-verifiable
 * proof in environments without Flutter SDK. Run: node tools/verify_state_contract.mjs
 */
import assert from 'node:assert/strict';
import test from 'node:test';

const slots=['top','outer','bottom','dress','shoes','hat'];
const catalog = new Map([
  ['t1',{slot:'top',owned:true}],['t2',{slot:'top',owned:true}],
  ['b1',{slot:'bottom',owned:true}],['b2',{slot:'bottom',owned:true}],
  ['d1',{slot:'dress',owned:true}],['s1',{slot:'shoes',owned:true}],
  ['s2',{slot:'shoes',owned:true}],['o1',{slot:'outer',owned:true}],
  ['h1',{slot:'hat',owned:true}],['foreign',{slot:'top',owned:false}],
]);
const empty=()=>Object.fromEntries(slots.map(s=>[s,null]));
const clean=(s)=>Object.fromEntries(slots.map(k=>[k,s[k]??null]));
class Rules {
  constructor(){this.items=new Map(catalog);this.s={style:'minimal',ids:empty(),locks:new Set(),rev:0};}
  check(slot,id){
    const item=this.items.get(id);
    if(!item||!item.owned)throw Error('not-owned');
    if(item.slot!==slot)throw Error('wrong-slot');
  }
  commit(ids,locks,style=this.s.style){
    const next=clean(ids);
    for(const slot of slots)if(next[slot])this.check(slot,next[slot]);
    if(next.dress && (next.top || next.bottom))throw Error('dress-conflict');
    for(const slot of locks)if(!next[slot])throw Error('lock-empty');
    this.s={style,ids:next,locks:new Set(locks),rev:this.s.rev+1};
  }
  select(slot,id,{replaceLocked=false,clearConflictingLocks=false,lockSelected=true}={}){
    this.check(slot,id);
    if(this.s.locks.has(slot)&&this.s.ids[slot]!==id&&!replaceLocked)throw Error('locked');
    const next={...this.s.ids},locks=new Set(this.s.locks);
    const conflicts=slot==='dress'?['top','bottom']:slot==='top'||slot==='bottom'?['dress']:[];
    for(const conflict of conflicts){
      if(locks.has(conflict)&&!clearConflictingLocks)throw Error('conflict-locked');
      next[conflict]=null;locks.delete(conflict);
    }
    next[slot]=id;
    if(lockSelected)locks.add(slot);else locks.delete(slot);
    this.commit(next,locks);
  }
  clear(slot,{force=false}={}){
    if(this.s.locks.has(slot)&&!force)throw Error('locked');
    if(!this.s.ids[slot])return;
    const next={...this.s.ids},locks=new Set(this.s.locks);
    next[slot]=null;locks.delete(slot);this.commit(next,locks);
  }
  toggleLock(slot){
    if(!this.s.ids[slot])throw Error('lock-empty');
    const locks=new Set(this.s.locks);
    if(locks.has(slot))locks.delete(slot);else locks.add(slot);
    this.commit(this.s.ids,locks);
  }
  setStyle(style){if(style!==this.s.style)this.commit(this.s.ids,this.s.locks,style);}
  applyRec(ids,style=this.s.style){
    const next=clean(ids);
    for(const slot of slots)if(next[slot])this.check(slot,next[slot]);
    if(next.dress&&(next.top||next.bottom))throw Error('dress-conflict');
    for(const slot of this.s.locks)if(next[slot]!==this.s.ids[slot])throw Error('locked');
    this.commit(next,this.s.locks,style);
  }
  get complete(){return Boolean(this.s.ids.shoes&&(this.s.ids.dress||(this.s.ids.top&&this.s.ids.bottom)));}
  restore(saved){
    const ids=empty();
    for(const slot of slots){
      const id=saved.ids[slot];
      if(id&&this.items.has(id)&&this.items.get(id).owned&&this.items.get(id).slot===slot)ids[slot]=id;
    }
    if(ids.dress){ids.top=null;ids.bottom=null;}
    this.commit(ids,new Set(),saved.style);
  }
  replaceCatalog(removeId){
    this.items.delete(removeId);
    const ids={...this.s.ids},locks=new Set(this.s.locks);
    for(const slot of slots)if(ids[slot]&&!this.items.has(ids[slot])){ids[slot]=null;locks.delete(slot);}
    this.commit(ids,locks);
  }
}

test('C01 初始化六个槽位为空',()=>{
  const c=new Rules();assert.equal(Object.values(c.s.ids).filter(Boolean).length,0);assert.equal(c.complete,false);
});
test('C02 选择上衣→选中并锁定',()=>{
  const c=new Rules();c.select('top','t1');assert.equal(c.s.ids.top,'t1');assert.ok(c.s.locks.has('top'));assert.equal(c.s.rev,1);
});
test('C03 类别错误拒绝',()=>{
  const c=new Rules();assert.throws(()=>c.select('top','s1'));assert.equal(c.s.rev,0);
});
test('C04 非个人衣柜单品拒绝',()=>{
  const c=new Rules();assert.throws(()=>c.select('top','foreign'));assert.throws(()=>c.select('top','missing'));
});
test('C05 锁定单品不能静默换；确认后可替换',()=>{
  const c=new Rules();c.select('top','t1');const r=c.s.rev;assert.throws(()=>c.select('top','t2'));assert.equal(c.s.rev,r);c.select('top','t2',{replaceLocked:true});assert.equal(c.s.ids.top,'t2');
});
test('C06 连衣裙与上下装互斥，锁定时须确认',()=>{
  const c=new Rules();c.select('top','t1');c.select('bottom','b1');assert.throws(()=>c.select('dress','d1'));
  c.select('dress','d1',{clearConflictingLocks:true});assert.equal(c.s.ids.dress,'d1');assert.equal(c.s.ids.top,null);assert.equal(c.s.ids.bottom,null);assert.ok(!c.s.locks.has('top'));
});
test('C07 连衣裙 + 鞋子是完整套装',()=>{
  const c=new Rules();c.select('dress','d1');assert.equal(c.complete,false);c.select('shoes','s1');assert.equal(c.complete,true);
});
test('C08 上衣 + 下装必须再有鞋子',()=>{
  const c=new Rules();c.select('top','t1');c.select('bottom','b1');assert.equal(c.complete,false);c.select('shoes','s1');assert.equal(c.complete,true);
});
test('C09 切换风格不改变已选衣服',()=>{
  const c=new Rules();c.select('top','t1');const ids={...c.s.ids};c.setStyle('korean');assert.deepEqual(c.s.ids,ids);assert.equal(c.s.style,'korean');
});
test('C10 覆盖锁定单品的推荐原子拒绝',()=>{
  const c=new Rules();c.select('top','t1');const old=c.s;
  assert.throws(()=>c.applyRec({...empty(),top:'t2',bottom:'b1',shoes:'s1'}));
  assert.strictEqual(c.s,old);assert.equal(c.s.ids.top,'t1');
});
test('C11 非法商品推荐原子拒绝',()=>{
  const c=new Rules();const old=c.s;
  assert.throws(()=>c.applyRec({...empty(),top:'t1',bottom:'not-owned',shoes:'s1'}));
  assert.strictEqual(c.s,old);
});
test('C12 允许匹配锁定单品的合法推荐',()=>{
  const c=new Rules();c.select('top','t1');
  c.applyRec({...empty(),top:'t1',bottom:'b1',shoes:'s1'},'korean');
  assert.ok(c.complete);assert.equal(c.s.ids.top,'t1');assert.ok(c.s.locks.has('top'));assert.equal(c.s.style,'korean');
});
test('C13 空槽位禁止上锁',()=>{
  const c=new Rules();assert.throws(()=>c.toggleLock('hat'));assert.equal(c.s.rev,0);
});
test('C14 直接删除锁定单品拒绝，强制删除清理锁',()=>{
  const c=new Rules();c.select('top','t1');assert.throws(()=>c.clear('top'));
  c.clear('top',{force:true});assert.equal(c.s.ids.top,null);assert.equal(c.s.locks.size,0);
});
test('C15 删除真实衣服后恢复收藏应保留缺失位',()=>{
  const c=new Rules();c.select('top','t1');c.select('bottom','b1');c.select('shoes','s1');
  const saved={ids:{...c.s.ids},style:c.s.style};c.replaceCatalog('b1');c.restore(saved);
  assert.equal(c.s.ids.bottom,null);assert.equal(c.s.ids.top,'t1');assert.equal(c.s.ids.shoes,'s1');assert.equal(c.s.locks.size,0);
});
test('C16 推荐不能让 dress 与普通上衣同时存在',()=>{
  const c=new Rules();const old=c.s;
  assert.throws(()=>c.applyRec({...empty(),top:'t1',dress:'d1',shoes:'s1'}));
  assert.strictEqual(c.s,old);
});
