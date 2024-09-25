<template>
  <span v-for="card in event.cards_used">
    <Card :card="card"></Card>
  </span>
  <span>{{ event.rule }}</span>
  <span v-for="card in event.effect.discard">
    棄<Card :card="card"></Card>
  </span>
</template>
<script>
import Card from './card.vue';

export default {
  components: {
    Card
  },
  props: ['event']
}
</script>
