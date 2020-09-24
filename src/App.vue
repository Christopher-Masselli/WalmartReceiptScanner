<template>
  <v-app>

    <v-content>
      <v-btn @click="parseImage"
      >
        {{debug}}
      </v-btn>
      <input id="target" type="file" accept="image/*" >
      <video autoplay/>
      <v-progress-circular
      v-if="progress != 0"
      color="00F"
      :value="progress">
      </v-progress-circular>
      <img ref="image"  />
      <v-data-table
        v-model="selected"
        :headers="headers"
        :items="finaleIndex"
        item-key="index"
        show-select
        disable-pagination
        hide-default-footer
        :loading="progress < 100 && progress > 0"
        loading-text="Loading... Please wait"
        class="elevation-1"
        >
        <template slot="footer" >
          <div class="v-data-footer"
          :style="{'background-color':
           (Math.abs(totalPrice -
            parseFloat(this.total.split(' ')[1])) < 2)? 'green' : 'red'}">
            <td><strong>Calculated</strong></td>
            <td class="text-xs-left">{{ totalPrice }}</td>
            <td><strong>Found</strong></td>
            <td class="text-xs-right">{{ total }}</td>
          </div>
        </template>
  </v-data-table>

    </v-content>
  </v-app>
</template>

<script lang="ts">
import Vue from 'vue';
import {createWorker} from 'tesseract.js';
import {stringify} from 'querystring';
// import loadImage from 'blueimp-load-image';
const testData = require('./jsonformatter.json');
import ImageLoad from 'blueimp-load-image';
// const groceryData = () => import('./data.js');
// import tesseract from 'tesseract.js'

export default Vue.extend({
  name: 'App',

  components: {
  },
  computed: {
    totalPrice() {
      return this.finale.reduce((prev: any, item: any, index: Number)=>{
        if (item.price != null) {
          return prev + parseFloat(item.price) * (item.qty ? item.qty : 1);
        }
        return prev;
      }, 0 as number );
    },
    finaleIndex() {
      return this.finale.map((item, index) => {
        return ({
          ...item,
          index: index,
        })
        ;
      });
    },
  },
  watch: {
    selected(newValue, oldValue) {
      console.log(newValue);
    },
  },
  mounted() {
    const target = document.getElementById('target');
    if (target) {
      target.addEventListener('change', (e: any) =>
        this.handleUpload(e.target.files));
    }
  },
  data: () => ({
    // eslint-disable-next-line max-len
    text: 'To win $1000 ID #: TKZGF 15L2FF W t 34 almart -~ Save money, Live better, ( 970 ) 269 - 8765 MANAGER MIKE NEIDLINGER & 1166 S CAMINO DEL RIO DURANGD CO 81303 ST# 02270 OP# 000144 TE# 02 TR# 03080 < PANANAS 00000000401 1KI 1.76 1b @ 1 lb /0.64 0.95 R BEVERAGE 003120002133 F 2.00 R 0S CRAN POM 003120027016 F 2.00 R STRWBRY CC 076471782200 F 0.96 Y CAMPARI TOM 073447501213 I 2.98 R KFT SINGLES 002100061526 F 3.718 Y 44600982114 004450098211 F 3.98 Y HARD SALAMI 020633960343 F 3.43 Y AVOCADD 000000004046KI 4 AT 1 FOR 0.44 1.76 R PILLS WHITE 068113113619 F 15200;.Y. SH NYLON COL 007417024836 2.97 X HAND CLEANER 004125100005 1.67 X INJECTR CLNR 004980710003 B.BT X SUBTOTAL %6.35 TAX 1 7.900 % 1.07 TAX 2 5.000 % 1.14 TAX B 2.900 % 0.12 TOTAL 38.68 CASH TEND 40.68 CHANGE DUE 2.00 # ITEMS SOLD 16 T 01716717 14:26:03 EiRsE 0 T 2w b L',
    ids: [] as String[],
    selected: [],
    itemsFound: new Map(),
    progress: 0,
    debug: '',
    total: '',
    output: 'null',
    lines: new Map(),
    src: null as any,
    file: null as any,
    finale: [] as String[],
    headers: [
      {
        text: 'Name',
        align: 'start',
        sortable: false,
        value: 'name',
      },
      {text: 'Id', value: 'id'},
      {text: 'Price($)', value: 'price'},
      {text: 'Quanity', value: 'qty'},
    ],
  }),
  methods: {
    async handleUpload(files: any) {
      this.output = files.length;
      this.debug = 'loading';
      this.file = files[0];

      this.text = '';
      this.ids = [];
      const image = this.$refs['image'] as any;
      image.src = (window.URL ?
       URL : webkitURL).createObjectURL(this.file);
      this.debug = 'loaded';
      await this.format();
    },
    parseImage() {
      const worker = createWorker({
        logger: (m: any) => {
          this.debug = m.status;
          this.output = stringify(m);
          if (m.jobId) {
            this.progress = m.progress * 100;
          }
        },
      });
      (async (fnc : any) => {
        this.debug = 'starting worker';
        await worker.load();
        await worker.loadLanguage('eng');
        await worker.initialize('eng');
        this.progress = .0001;
        const {data: {text}} = await worker.recognize(this.file);
        this.text = text;
        console.log(text);
        await worker.terminate();
        fnc();
      })(this.getids);
    },
    getids() {
      this.debug = 'Getting Ids';
      const digitReg = /(\d{9,})/g;
      const totalReg = /((\w*TOTAL)+ *(\d+\.*\d*){1})/g;
      const lineReg = /(.+(\d{9,}){1}.+)|(.*(AT).*(FOR).*)/g;
      const idsRaw = [...this.text.matchAll(digitReg)];
      const receiptLines = [...this.text.matchAll(lineReg)];
      this.total = ([...this.text.matchAll(totalReg)])[0][0];
      let prev;
      for (const line of receiptLines) {
        let name : string;
        let id : string;
        let price : string;
        const reversed = line[0].split(' ').reverse();
        console.log(line);

        if (reversed != undefined && reversed.length >= 2) {
          if (reversed.includes('FOR')) {
            price = reversed[1];
            if (prev != undefined) {
              name = ((prev.slice(1))
                  .reverse().toString()).replace(',', ' ');
              id = prev[0];
              this.lines.set(id, {name, price});
              this.ids.push(id);
            }
          } else if (reversed[1].indexOf('.') != -1) {
            if (reversed[2] != undefined && reversed[2].length === 1) {
              id = reversed[3];
              name = ((reversed.slice(4))
                  .reverse().toString()).replace(',', ' ');
              price = reversed[1];
            } else {
              id = reversed[2];
              name = ((reversed.slice(3))
                  .reverse().toString()).replace(',', ' ');
              price = reversed[1];
            }
            this.lines.set(id, {name,
              price,
              qty: this.lines.get(id) ? this.lines.get(id).qty + 1 : 1,
            });
          }
          prev = reversed;
        }
      }
      // for (const item of total) {
      //   this.total = item[0];
      // }
      for (const raw of idsRaw ) {
        this.ids.push(raw[0]);
      }
      this.resolveids();
    },
    resolveids() {
      this.debug = 'Resolving Ids';
      for (const id of this.ids) {
        for (const item of testData.data) {
          if ( item.upc14.includes(id) || item.upc12.includes(id)) {
            this.itemsFound.set(id, item );
            break;
          }
        }
      }
      for (const line of this.lines ) {
        this.finale.push({id: line[0], ...line[1]});
      }
      // this.finale = this.ids.reduce(
      //     (outputArray: any[], cId: String, index: Number) => {
      //       if (this.lines.has(cId)) {
      //         if (this.itemsFound.has(cId)) {
      //           outputArray.push({
      //             id: cId,
      //             ...this.lines.get(cId),
      //             name: this.itemsFound.get(cId).name,
      //           });
      //         } else {
      //           outputArray.push({id: cId, ...this.lines.get(cId)});
      //         }
      //       }
      //       return outputArray;
      //     }, [] as String[]);

      this.debug = 'Finished';
    },
    async format() {
      const image = this.$refs['image'] as HTMLImageElement;
      this.debug = 'Rotating';
      // eslint-disable-next-line new-cap
      await ImageLoad(
          image.src,
          await this.displayMetaData,
          {meta: true,
            orientation: true,
            maxWidth: '400px',
            maxHeight: '500px',
          } as any,
      );
    },
    displayMetaData(img : any, data : any) {
      this.debug = 'setting rotation';

      const image = this.$refs['image'] as any;
      img.toBlob((blob : any) => {
        this.file= blob;
      }, 'image/jpeg', 1);
      image.src = img.toDataURL();
      if (!data) return;
      const exif = data.exif;
      // const iptc = data.iptc;
      if (exif) {
        console.log(exif.get('Orientation'));
      };
    },
  },
});
</script>

<style lang="scss" scoped>
</style>
