<template>
  <Turn v-for="turn in turns" :class="turn_owner" :turn="turn"></Turn>
</template>
<script>
import { Game } from './games/game'
import Turn from './turn.vue'
export default {
  data() {
    return {
      turns: [],
      game: new Game()
    }
  },
  components: {
    Turn
  },
  mounted() {
    console.log("event list is mounted")
    this.get_event_list()
  },
  methods: {
    get_event_list: function() {
      fetch(this.game.generate_url("event_list", $("#maincontainer").data("game_id"), $("#player").data("id")))
        .then((response) => response.json())
        .then((data) => {
            console.log(data)
            this.turns = data
          })
    }
  }
}
</script>
