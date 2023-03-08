import { StatusBar } from 'expo-status-bar'
import { useEffect } from 'react'
import { StyleSheet, Text, View } from 'react-native'
import * as shareExtensionNativeModule from 'share-extension-expo-plugin'

export default function App() {
  useEffect(() => {
    shareExtensionNativeModule.setKeychainValue('api', 'https://jsonplaceholder.typicode.com')
  }, [])

  return (
    <View style={styles.container}>
      <Text>Welcome to this example</Text>
      <Text>Powered by 'https://jsonplaceholder.typicode.com'</Text>
      <StatusBar style="auto" />
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
})
