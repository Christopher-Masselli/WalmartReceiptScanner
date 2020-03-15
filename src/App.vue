<template>
  <v-app>

    <v-content>
      <v-btn @click="getids"
      >
        {{debug}}
      </v-btn>
      <v-progress-circular
      v-if="progress!=0"
      color="00F"
      :value="progress">
      </v-progress-circular>
     <input id="target" type="file" accept="image/*" capture="environment">
     <v-sheet>
       {{ids}}
     </v-sheet>
     <v-sheet v-for="item in items" :key="item.upc12">
       {{item.name}}
     </v-sheet>
    </v-content>
  </v-app>
</template>

<script lang="ts">
import Vue from 'vue';
import HelloWorld from './components/HelloWorld.vue';
import {createWorker} from 'tesseract.js';
const testData = require('./jsonformatter.json');
// const groceryData = () => import('./data.js');
// import tesseract from 'tesseract.js'

export default Vue.extend({
  name: 'App',

  components: {
    HelloWorld,
  },
  mounted() {
    const target = document.getElementById('target');
    if (target) {
      target.addEventListener('change', (e: any) =>
        this.handleUpload(e.target.files));
    }
  },
  data: () => ({
    player: {} as HTMLMediaElement,
    src: '',
    // eslint-disable-next-line max-len
    text: 'To win $1000 ID #: TKZGF 15L2FF W t 34 almart -~ Save money, Live better, ( 970 ) 269 - 8765 MANAGER MIKE NEIDLINGER & 1166 S CAMINO DEL RIO DURANGD CO 81303 ST# 02270 OP# 000144 TE# 02 TR# 03080 < PANANAS 00000000401 1KI 1.76 1b @ 1 lb /0.64 0.95 R BEVERAGE 003120002133 F 2.00 R 0S CRAN POM 003120027016 F 2.00 R STRWBRY CC 076471782200 F 0.96 Y CAMPARI TOM 073447501213 I 2.98 R KFT SINGLES 002100061526 F 3.718 Y 44600982114 004450098211 F 3.98 Y HARD SALAMI 020633960343 F 3.43 Y AVOCADD 000000004046KI 4 AT 1 FOR 0.44 1.76 R PILLS WHITE 068113113619 F 15200;.Y. SH NYLON COL 007417024836 2.97 X HAND CLEANER 004125100005 1.67 X INJECTR CLNR 004980710003 B.BT X SUBTOTAL %6.35 TAX 1 7.900 % 1.07 TAX 2 5.000 % 1.14 TAX B 2.900 % 0.12 TOTAL 38.68 CASH TEND 40.68 CHANGE DUE 2.00 # ITEMS SOLD 16 T 01716717 14:26:03 EiRsE 0 T 2w b L',
    ids: [] as String[],
    items: [] as Object[],
    progress: 0,
    debug: '',
  }),
  methods: {
    handleUpload(files: any) {
      const file = files[0];
      this.text = '';
      this.ids = [];
      const worker = createWorker({
        logger: (m: any) => {
          console.log(m);
          this.debug= m.status;
          if (m.jobId) {
            this.progress = m.progress * 100;
          }
        }, // Add logger here
      });
      (async (fnc : any) => {
        await worker.load();
        await worker.loadLanguage('eng');
        await worker.initialize('eng');
        const {data: {text}} = await worker.recognize(file);
        this.text = text;
        await worker.terminate();
        fnc();
      })(this.getids);
    },
    getids() {
      console.log('getting');
      const digitReg = /(\d{12})/g;
      console.log(this.text);
      const idsRaw = [...this.text.matchAll(digitReg)];
      console.log(idsRaw);
      for (const raw of idsRaw ) {
        this.ids.push(raw[0]);
      }
      this.resolveids();
    },
    resolveids() {
      for (const id of this.ids) {
        for (const item of testData.data) {
          if ( item.upc14.includes(id) || item.upc12.includes(id)) {
            console.log(item);
            this.ids.splice(this.ids.indexOf(item), 1);
            this.items.push(item);
            break;
          }
        }
      }
    },
  },
});
</script>
